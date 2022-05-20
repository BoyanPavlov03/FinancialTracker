//
//  AuthHandler.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 5.02.22.
//

import Foundation
import Firebase
import FirebaseAuth

enum AuthError: Error {
    case auth(Error?)
    case signOut(Error?)
    case database(DatabaseError?)
    case unknown(String?)
    
    var title: String {
        switch self {
        case .auth(let error):
            if error != nil {
                return "Auth Error"
            }
            return "Unknown Auth Error"
        case .signOut(let error):
            if error != nil {
                return "Sign Out Error"
            }
            return "Unknown Sign Out Error"
        case .database(let databaseError):
            return databaseError?.title ?? "Unknown Database Error"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    var message: String {
        switch self {
        case .auth(let error):
            return error?.localizedDescription ?? ""
        case .signOut(let error):
            return error?.localizedDescription ?? ""
        case .database(let error):
            return error?.message ?? ""
        case .unknown(let error):
            return error ?? ""
        }
    }
}

enum DBCollectionKey: String {
    case users
    case transfers
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
    ///     1. `authError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func checkAuthorisedState(completionHandler: @escaping (AuthError?, User?) -> Void) {
        auth.addStateDidChangeListener { _, user in
            if let user = user {
                self.databaseManager.getCurrentUserData(uid: user.uid) { databaseError, user in
                    completionHandler(AuthError.database(databaseError), user)
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
    ///     1. `authError` - An error object that indicates why the function     failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func registerUser(firstName: String, lastName: String, email: String, password: String, completionHandler: @escaping (AuthError?, User?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] (result, error) in

            guard let self = self else {
                fatalError("self is nil")
            }
            
            guard error == nil else {
                completionHandler(AuthError.auth(error), nil)
                return
            }

            guard let result = result else {
                completionHandler(AuthError.unknown("We don't have a returned user."), nil)
                return
            }

            self.databaseManager.createUser(firstName: firstName, lastName: lastName, email: email, uid: result.user.uid) { databaseError, user in
                if let databaseError = databaseError {
                    completionHandler(AuthError.database(databaseError), nil)
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
    ///     1. `authError` - An error object that indicates why the function     failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func logInUser(email: String, password: String, completionHandler: @escaping (AuthError?, User?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            guard error == nil else {
                completionHandler(AuthError.auth(error), nil)
                return
            }

            guard let result = result else {
                completionHandler(AuthError.unknown("We don't have a returned user."), nil)
                return
            }
            
            self.databaseManager.getCurrentUserData(uid: result.user.uid) { databaseError, user in
                completionHandler(AuthError.database(databaseError), user)
            }
        }
    }
    
    /// Signing out the current user
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `authError` - An error object that indicates why the function     failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func signOut(completionHandler: @escaping (AuthError?, Bool) -> Void) {
        do {
            try auth.signOut()
            self.databaseManager.removeFCMTokenFromCurrentUser { databaseError, success in
                if let databaseError = databaseError {
                    completionHandler(AuthError.database(databaseError), false)
                    return
                }
                completionHandler(nil, success)
            }
        } catch let signOutError {
            completionHandler(AuthError.signOut(signOutError), false)
        }
    }
    
    func addBalanceToCurrentUser(_ balance: Double, currency: Currency, completionHandler: @escaping (AuthError?, Bool) -> Void) {
        databaseManager.addBalanceToCurrentUser(balance, currency: currency) { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
    
    func addTransactionToUserByUID(_ uid: String, amount: Double, category: Category, date: Date, completionHandler: @escaping (AuthError?, Bool) -> Void) {
        databaseManager.addTransactionToUserByUID(uid, amount: amount, category: category, date: date) { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
    
    func addScoreToCurrentUser(basedOn time: Double, completionHandler: @escaping (AuthError?, Bool) -> Void) {
        databaseManager.addScoreToCurrentUser(basedOn: time) { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
    
    func changeCurrentUserCurrency(_ currency: Currency, completionHandler: @escaping (AuthError?, Bool) -> Void) {
        databaseManager.changeCurrentUserCurrency(currency) { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
    
    func buyPremium(completionHandler: @escaping (AuthError?, Bool) -> Void) {
        databaseManager.buyPremium { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
    
    func transferMoney(email: String, amount: Double, transferType: TransferType, completionHandler: @escaping (AuthError?, User?) -> Void) {
        databaseManager.transferMoney(email: email, amount: amount, transferType: transferType) { databaseError, user in
            completionHandler(AuthError.database(databaseError), user)
        }
    }
    
    func completeTransfer(transfer: Transfer, completionHandler: @escaping(AuthError?, Bool) -> Void) {
        databaseManager.completeTransfer(transfer: transfer) { databaseError, success in
            completionHandler(AuthError.database(databaseError), success)
        }
    }
        
    func firestoreDidChangeUserData(completionHandler: @escaping (AuthError?, User?) -> Void) {
        databaseManager.firestoreDidChangeUserData { databaseError, user in
            completionHandler(AuthError.database(databaseError), user)
        }
    }
    
    func firestoreDidChangeUserTransfersData(completionHandler: @escaping (AuthError?, [Transfer]?) -> Void) {
        databaseManager.firestoreDidChangeUserTransfersData { databaseError, transfers in
            completionHandler(AuthError.database(databaseError), transfers)
        }
    }
    
    func getAllUsers(completionHandler: @escaping (AuthError?, [String]?) -> Void) {
        databaseManager.getAllUsers { databaseError, emails in
            completionHandler(AuthError.database(databaseError), emails)
        }
    }
    
    func addDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
    
    func removeDelegate(_ delegate: DatabaseManagerDelegate) {
        databaseManager.addDelegate(delegate)
    }
}
