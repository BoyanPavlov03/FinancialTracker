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
    
    func checkAuthorisedState(completionHandler: @escaping (User?) -> Void) {
        auth.addStateDidChangeListener { _, user in
            if let user = user {
                self.databaseManager.getCurrentUserData(uid: user.uid) { firebaseError, user in
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
    
    func addTransactionToUserByUID(_ amount: Double, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let uid = currentUser?.uid else { return }
        databaseManager.addTransactionToUserByUID(uid, amount: amount, category: category) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func addScoreToUserBasedOnTime(_ time: Double, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.addScoreToUserBasedOnTime(time) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func changeCurrency(_ currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.changeCurrency(currency) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func buyPremium(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.buyPremium { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func setReminder(type: TransferType, description: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.setReminder(type: type, description: description) { firebaseError, success in
            completionHandler(firebaseError, success)
        }
    }
    
    func deleteReminder(_ reminder: Reminder, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        databaseManager.deleteReminder(reminder) { firebaseError, success in
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
    
    func addDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
    
    func removeDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
}
