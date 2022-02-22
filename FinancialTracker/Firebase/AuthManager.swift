//
//  AuthHandler.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 5.02.22.
//

import Foundation
import Firebase
import FirebaseAuth

enum FirebaseError: Error {
    case auth(Error?)
    case database(Error?)
    case signOut(Error?)
    case access(String?)
    case unknown
    case nonExistingUser
}

enum DBCollectionKey: String {
    case users
}

/// Class for managing all authentication related actions.
class AuthManager {
    private let auth: Auth
    private let databaseManager: DatabaseManager
    
    var currentUser: User? {
        guard let user = databaseManager.currentUser else {
            return nil
        }
        
        return user
    }
    
    init() {
        self.auth = Auth.auth()
        self.databaseManager = DatabaseManager()
    }
    
    /// Listener for auth changes.
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///   - firebaseError: An error object that indicates why the function failed, or nil if the was successful.
    ///   - user: The user that was returned by firestore.
    func checkAuthorisedState(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        auth.addStateDidChangeListener { _, user in
            if let user = user {
                self.databaseManager.getCurrentUserData(uid: user.uid) { firebaseError, user in
                    completionHandler(firebaseError, user)
                }
            } else {
                // There can be no user but that doesn't mean there is an error
                completionHandler(nil, nil)
            }
        }
    }
    
    /// Registering an user and saving data to firestore.
    /// - Parameters:
    ///   - firstName: A `String` containing the user's first name.
    ///   - lastName: A `String` containing the user's last name.
    ///   - email: A `String` containing the user's email.
    ///   - password: A `String` containing the user's password.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///   - firebaseError: An error object that indicates why the function failed, or nil if the was successful.
    ///   - user: The user that was returned by firestore.
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

            self.databaseManager.createUser(firstName: firstName, lastName: lastName, email: email, uid: result.user.uid) { firebaseError, user in
                if let firebaseError = firebaseError {
                    completionHandler(firebaseError, nil)
                    return
                }
                
                let user = User(firstName: firstName, lastName: lastName, email: email, uid: result.user.uid, score: 0)
                completionHandler(nil, user)
            }
        }
    }

    /// Logging an user via password
    /// - Parameters:
    ///   - email: A `String` containing the user's email.
    ///   - password: A `String` containing the user's password.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///   - firebaseError: An error object that indicates why the function failed, or nil if the was successful.
    ///   - user: The user that was returned by firestore.
    func logInUser(email: String, password: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            guard error == nil else {
                completionHandler(FirebaseError.auth(error), nil)
                return
            }

            guard let result = result else {
                return
            }
            
            self.databaseManager.getCurrentUserData(uid: result.user.uid) { firebaseError, user in
                if let firebaseError = firebaseError {
                    switch firebaseError {
                    case .database(let error):
                        completionHandler(FirebaseError.database(error), user)
                    case .unknown:
                        completionHandler(FirebaseError.unknown, user)
                    case .access(let error):
                        completionHandler(FirebaseError.access(error), user)
                    case .auth, .signOut, .nonExistingUser:
                        assertionFailure("This error should not appear: \(firebaseError.localizedDescription)")
                        // swiftlint:disable:next unneeded_break_in_switch
                        break
                    }
                } else {
                    completionHandler(nil, user)
                }
            }
        }
    }
    
    /// Signing out the current user
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///   - firebaseError: An error object that indicates why the function failed, or nil if the was successful.
    ///   - user: The user that was returned by firestore.
    func signOut(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        do {
            try auth.signOut()
            self.databaseManager.removeFCMTokenFromCurrentUser { firebaseError, success in
                self.databaseManager.setUserToNil()
                completionHandler(firebaseError, success)
            }
        } catch let signOutError {
            completionHandler(FirebaseError.signOut(signOutError), false)
        }
    }
    
    func addBalanceToCurrentUser(_ balance: Double, currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.addBalanceToCurrentUser(balance, currency: currency) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func addTransactionToCurrentUser(amount: Double, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.addTransactionToCurrentUser(amount: amount, category: category) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func addScoreToCurrentUser(basedOn time: Double, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.addScoreToCurrentUser(basedOn: time) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func changeCurrentUserCurrency(_ currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.changeCurrentUserCurrency(currency) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func buyPremium(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.buyPremium { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func setReminderToCurrentUser(transferType: TransferType, description: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.setReminderToCurrentUser(transferType: transferType, description: description) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func deleteReminderFromCurrentUser(reminder: Reminder, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.deleteReminderFromCurrentUser(reminder: reminder) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func transferMoney(email: String, amount: Double, transferType: TransferType, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        auth.fetchSignInMethods(forEmail: email) { methods, error in
            if error != nil {
                completionHandler(FirebaseError.nonExistingUser, nil)
                return
            }
            
            guard methods != nil else {
                completionHandler(FirebaseError.nonExistingUser, nil)
                return
            }
            
            self.databaseManager.transferMoney(email: email, amount: amount, transferType: transferType) { firebaseError, user in
                completionHandler(firebaseError, user)
            }
        }
    }
    
    func firestoreDidChangeData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        databaseManager.firestoreDidChangeData { firebaseError, user in
            completionHandler(firebaseError, user)
        }
    }
    
    func getAllUsers(completionHandler: @escaping (FirebaseError?, [String]?) -> Void) {
        databaseManager.getAllUsers { firebaseError, emails in
            completionHandler(firebaseError, emails)
        }
    }
    
    func addDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
    
    func removeDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
}
