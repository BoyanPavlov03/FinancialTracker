//
//  Firebase.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 15.12.21.
//

import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

enum FirebaseError: Error {
    case auth(Error?)
    case database(Error?)
    case signOut(Error?)
    case access(String?)
    case unknown
}

enum DBCollectionKey: String {
    case users
}

protocol FirebaseHandlerDelegate: AnyObject {
    func firebaseHandlerDidUserChange(sender: FirebaseHandler)
}

class FirebaseHandler {
    // MARK: - Properties
    static let shared = FirebaseHandler()
    var currentUser: User? {
        guard signedIn else {
            return nil
        }
        
        return user
    }
    
    // MARK: - Private properties
    private var user: User!
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    private let delegatesCollection = DelegatesCollection<FirebaseHandlerDelegate>()
    
    private var signedIn: Bool {
        return auth.currentUser != nil
    }
    
    private init() {}
    
    // MARK: - Methods
    func checkAuthorisedState(completionHandler: @escaping (User?) -> Void) {
        auth.addStateDidChangeListener { _, user in
            if user != nil {
                self.getCurrentUserData { firebaseError, user in
                    if let firebaseError = firebaseError {
                        assertionFailure("Can't access user data: \(firebaseError.localizedDescription)")
                        return
                    }
                    
                    completionHandler(user)
                }
            } else {
                completionHandler(nil)
            }
        }
    }
    
    func registerUser(firstName: String, lastName: String, email: String, password: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] (result, error) in

            guard let self = self else {
                fatalError("self is nil")
            }
            
            guard error == nil else {
                completionHandler(FirebaseError.auth(error), nil)
                return
            }

            guard let result = result else {
                completionHandler(FirebaseError.unknown, nil)
                return
            }

            let firstNameKey = User.CodingKeys.firstName.rawValue
            let lastNameKey = User.CodingKeys.lastName.rawValue
            let uidKey = User.CodingKeys.uid.rawValue
            let emailKey = User.CodingKeys.email.rawValue
            let scoreKey = User.CodingKeys.score.rawValue
            let premiumKey = User.CodingKeys.premium.rawValue
            // swiftlint:disable:next line_length
            let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: result.user.uid, scoreKey: 0.0, premiumKey: false] as [String: Any]
                        
            self.firestore.collection(DBCollectionKey.users.rawValue).document(result.user.uid).setData(data) { error in
                if error != nil {
                    completionHandler(FirebaseError.database(error), nil)
                    return
                }
                
                self.user = User(firstName: firstName, lastName: lastName, email: email, uid: result.user.uid, score: 0)
                completionHandler(nil, self.user)
            }
        }
    }

    func logInUser(email: String, password: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            guard error == nil else {
                completionHandler(FirebaseError.auth(error), nil)
                return
            }

            self.getCurrentUserData { firebaseError, user in
                if let firebaseError = firebaseError {
                    switch firebaseError {
                    case .database(let error):
                        completionHandler(FirebaseError.database(error), user)
                    case .unknown:
                        completionHandler(FirebaseError.unknown, user)
                    case .access(let error):
                        completionHandler(FirebaseError.access(error), user)
                    case .auth, .signOut:
                        assertionFailure("This error should not appear: \(firebaseError.localizedDescription)")
                        // swiftlint:disable:next unneeded_break_in_switch
                        break
                    }
                } else {
                    self.user = user
                    completionHandler(nil, user)
                }
            }
        }
    }
    
    func signOut(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        do {
            try auth.signOut()
            self.user = nil
            completionHandler(nil, true)
        } catch let signOutError {
            completionHandler(FirebaseError.signOut(signOutError), false)
        }
    }
    
    func addBalanceToCurrentUser(_ balance: Double, currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        let currencyKey = User.CodingKeys.currency.rawValue
        
        do {
            let currencyData = try JSONEncoder().encode(currency)
            let json = try JSONSerialization.jsonObject(with: currencyData, options: [])
            
            guard let currencyValue = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
        
            firestore.collection(usersKey).document(currentUser.uid).updateData([balanceKey: balance, currencyKey: currencyValue])
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), false)
        }
    }
    
    func addExpenseToCurrentUser(_ expenseAmount: Double, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let expensesKey = User.CodingKeys.expenses.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        let formatedDate = today.formatDate("hh:mm:ss, MMM dd, yyyy")
        
        let expense = Expense(amount: expenseAmount, date: formatedDate, category: category)
                
        do {
            let expenseData = try JSONEncoder().encode(expense)
            let json = try JSONSerialization.jsonObject(with: expenseData, options: [])
            
            guard let dictionary = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
                        
            guard let userBalance = self.user.balance else {
                assertionFailure("User hasn't entered balance yet.")
                return
            }

            let newBalanceValue = (userBalance - expenseAmount).round(to: 2)
            let expenseValue = FieldValue.arrayUnion([dictionary])
            
            firestore.collection(usersKey).document(currentUser.uid).setData([expensesKey: expenseValue, balanceKey: newBalanceValue], merge: true)
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), true)
        }
    }
    
    func addScoreToUserBasedOnTime(_ time: Double, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        // A point is gained every 20 minutes
        let score = ((time / 60) / 20).round(to: 3)
        
        user.score += score
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData(["score": user.score], merge: true)
        completionHandler(nil, true)
    }
    
    func changeCurrency(_ currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser, let balance = currentUser.balance, let currentCurrency = currentUser.currency else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let newBalance = ((balance / currentCurrency.rate) * currency.rate).round(to: 2)
        
        var newExpenses: [Expense] = []
        for expense in currentUser.expenses {
            let newExpenseAmount = ((expense.amount / currentCurrency.rate) * currency.rate).round(to: 2)
            newExpenses.append(Expense(amount: newExpenseAmount, date: expense.date, category: expense.category))
        }
        
        let balanceKey = User.CodingKeys.balance.rawValue
        let expensesKey = User.CodingKeys.expenses.rawValue
        let currencyKey = User.CodingKeys.currency.rawValue
        
        do {
            let expenseData = try JSONEncoder().encode(newExpenses)
            let expensesJson = try JSONSerialization.jsonObject(with: expenseData, options: [])
                          
            guard let expensesValue = expensesJson as? [Any] else {
                assertionFailure("Couldn't cast json to array.")
                return
            }
            
            let currencyData = try JSONEncoder().encode(currency)
            let currencyJson = try JSONSerialization.jsonObject(with: currencyData, options: [])
            
            guard let currencyValue = currencyJson as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
                                 
            let data = [balanceKey: newBalance, expensesKey: expensesValue, currencyKey: currencyValue] as [String: Any]
            
            user.currency = currency
            user.expenses = newExpenses
            user.balance = newBalance
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData(data)
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), false)
        }
    }
    
    func buyPremium(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let premiumKey = User.CodingKeys.premium.rawValue
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData([premiumKey: true], merge: true)
        completionHandler(nil, true)
    }
    
    private func getCurrentUserData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        guard let uid = self.auth.currentUser?.uid else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), nil)
            return
        }
                
        self.firestore.collection(DBCollectionKey.users.rawValue).document(uid).addSnapshotListener { document, error in
            guard error == nil else {
                completionHandler(FirebaseError.database(error), nil)
                return
            }
            
            guard let json = document?.data() else {
                completionHandler(FirebaseError.unknown, nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                self.user = user
                
                self.delegatesCollection.forEach { delegate in
                    delegate.firebaseHandlerDidUserChange(sender: self)
                }
                
                completionHandler(nil, user)
            } catch {
                completionHandler(FirebaseError.database(error), nil)
            }
        }
    }
    
    // MARK: - DelegatesCollection Methods
    
    func addDelegate(_ delegate: FirebaseHandlerDelegate) {
        delegatesCollection.add(delegate: delegate)
    }
    
    func removeDelegate(_ delegate: FirebaseHandlerDelegate) {
        delegatesCollection.remove(delegate: delegate)
    }
}
