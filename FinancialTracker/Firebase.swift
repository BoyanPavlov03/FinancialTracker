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
    var expenses: [Expense] = []
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, uid, balance, expenses
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
                    guard firebaseError == nil else {
                        // swiftlint:disable:next force_unwrapping
                        assertionFailure("Can't access user data: \(firebaseError!.localizedDescription)")
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
            let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: result.user.uid]
                        
            self.firestore.collection(DBCollectionKey.users.rawValue).document(result.user.uid).setData(data) { error in
                if error != nil {
                    completionHandler(FirebaseError.database(error), nil)
                    return
                }
                
                self.user = User(firstName: firstName, lastName: lastName, email: email, uid: result.user.uid)
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
    
    func addBalanceToCurrentUser(_ balance: Int, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("You can't access that."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        self.user.balance = balance
        
        firestore.collection(usersKey).document(currentUser.uid).setData([balanceKey: balance], merge: true)
        
        completionHandler(nil, true)
    }
    
    func addExpenseToCurrentUser(_ expenseAmount: Int, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("You can't access that."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let expensesKey = User.CodingKeys.expenses.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        let dateformat = DateFormatter()
        dateformat.dateFormat = "MMM dd, yyyy"
        let date = Date()
        let formatedDate = dateformat.string(from: date)
        
        let expense = Expense(amount: expenseAmount, date: formatedDate, category: category)
                
        do {
            let expenseData = try JSONEncoder().encode(expense)
            let json = try JSONSerialization.jsonObject(with: expenseData, options: [])
            
            guard var dictionary = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
            
            dictionary["category"] = category.rawValue
            
            guard let userBalance = self.user.balance else {
                assertionFailure("User hasn't entered balance yet.")
                return
            }

            let newBalance = userBalance - expenseAmount
            let fieldValue = FieldValue.arrayUnion([dictionary])
            
            firestore.collection(usersKey).document(currentUser.uid).setData([expensesKey: fieldValue, balanceKey: newBalance], merge: true)
            
            self.user.expenses.append(expense)
            self.user.balance = newBalance
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), true)
        }
    }
    
    private func getCurrentUserData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        guard let uid = self.auth.currentUser?.uid else {
            completionHandler(FirebaseError.access("You can't access that."), nil)
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
