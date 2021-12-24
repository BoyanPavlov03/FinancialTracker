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
    case access
    case unknown
}

enum DBCollectionKey: String {
    case users
}

struct User: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let uid: String
    var balance: Int?
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, uid, balance
    }
}

class FirebaseHandler {
    // MARK: - Properties
    static let shared = FirebaseHandler()
    var currentUser: User? {
        guard signedIn else {
            return nil
        }
                        
        if user == nil {
            getCurrentUserData { firebaseError, user in
                guard firebaseError == nil else {
                    assertionFailure("Can't access user data")
                    return
                }
                self.user = user
            }
        }
                        
        return user
    }
    
    // MARK: - Private properties
    private var user: User!
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    
    var signedIn: Bool {
        return auth.currentUser != nil
    }
    
    private init() {}
    
    // MARK: - Methods
    func createUser(firstName: String, lastName: String, email: String, password: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
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

    func signIn(email: String, password: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
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
                case .none:
                    completionHandler(nil, user)
                    self.user = user
                default:
                    break
                }
            }
        }
    }
    
    func getCurrentUserData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        guard let uid = self.auth.currentUser?.uid else {
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
    
    func signOut(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        do {
            try auth.signOut()
            self.user = nil
        } catch let signOutError {
            completionHandler(FirebaseError.signOut(signOutError), false)
        }
    }
    
    func addBalanceToCurrentUser(_ balance: Int, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access, false)
            return
        }
        
        print(currentUser)
        
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        self.user.balance = balance
        
        firestore.collection(usersKey).document(currentUser.uid).setData([balanceKey: balance], merge: true)
    }
}
