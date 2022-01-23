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

struct Expense: Codable {
    let amount: Int
    let date: String
    let category: Category
    
    enum CodingKeys: String, CodingKey {
        case amount
        case date
        case category
    }
}

struct User: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let uid: String
    var balance: Int?
    var currency: Currency?
    var expenses: [Expense] = []
    var score: Double
    
    init(firstName: String, lastName: String, email: String, uid: String, score: Double) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.uid = uid
        self.score = score
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try values.decode(String.self, forKey: .firstName)
        lastName = try values.decode(String.self, forKey: .lastName)
        email = try values.decode(String.self, forKey: .email)
        uid = try values.decode(String.self, forKey: .uid)
        balance = try values.decodeIfPresent(Int.self, forKey: .balance)
        currency = try values.decodeIfPresent(Currency.self, forKey: .currency)
        expenses = try values.decodeIfPresent([Expense].self, forKey: .expenses) ?? []
        score = try values.decode(Double.self, forKey: .score)
    }
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, uid, balance, currency, expenses, score
    }
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
                    self.user = user
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
            let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: result.user.uid, scoreKey: 0.0] as [String: Any]
                        
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
                switch firebaseError {
                case .database(let error):
                    completionHandler(FirebaseError.database(error), user)
                case .unknown:
                    completionHandler(FirebaseError.unknown, user)
                case .access(let error):
                    completionHandler(FirebaseError.access(error), user)
                case .none:
                    self.user = user
                    completionHandler(nil, user)
                case .auth, .signOut:
                    // swiftlint:disable:next force_unwrapping
                    assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                    // swiftlint:disable:next unneeded_break_in_switch
                    break
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
    
    func addBalanceToCurrentUser(_ balance: Int, currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nill in #function."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        let currencyKey = User.CodingKeys.currency.rawValue
        
        self.user.balance = balance
        self.user.currency = currency
        
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
    
    func addExpenseToCurrentUser(_ expenseAmount: Int, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nill in #function."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let expensesKey = User.CodingKeys.expenses.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        let formatedDate = today.formatDate("MMM DD, YYYY")
        
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

            let newBalanceValue = userBalance - expenseAmount
            let expenseValue = FieldValue.arrayUnion([dictionary])
            
            firestore.collection(usersKey).document(currentUser.uid).setData([expensesKey: expenseValue, balanceKey: newBalanceValue], merge: true)
            
            self.user.expenses.append(expense)
            self.user.balance = newBalanceValue
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), true)
        }
    }
    
    func addScoreToUserBasedOnTime(_ time: Double, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nill in #function."), false)
            return
        }
        
        let score = ((time / 60) / 20).round(to: 3)
        user.score += score
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData(["score": user.score], merge: true)
        completionHandler(nil, true)
    }
    
    func changeCurrency(_ currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser, let balance = currentUser.balance, let currentCurrency = currentUser.currency else {
            completionHandler(FirebaseError.access("Current user is nill in #function."), false)
            return
        }
        
        let newBalance = (Double(balance) / currentCurrency.rate) * currency.rate
        
        var newExpenses: [Expense] = []
        for expense in currentUser.expenses {
            let newExpenseAmount = (Double(expense.amount) / currentCurrency.rate) * currency.rate
            newExpenses.append(Expense(amount: Int(newExpenseAmount), date: expense.date, category: expense.category))
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
            user.balance = Int(newBalance)
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData(data)
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), false)
        }
    }
    
    private func getCurrentUserData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        guard let uid = self.auth.currentUser?.uid else {
            completionHandler(FirebaseError.access("Current user is nill in #function."), nil)
            return
        }
        
        self.firestore.collection(DBCollectionKey.users.rawValue).document(uid).getDocument { document, error in
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
                completionHandler(nil, user)
            } catch {
                completionHandler(FirebaseError.database(error), nil)
            }
        }
    }
}
