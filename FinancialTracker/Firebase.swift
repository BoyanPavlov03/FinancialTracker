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
    case unknown
}

enum DBCollectionKey: String {
    case users
}

enum UserDataProperty: String {
    case firstName
    case lastName
    case uid
}

class FirebaseHandler {
    private let database = Firestore.firestore()
    private let auth = Auth.auth()
    static let shared = FirebaseHandler()
    
    private init() {}
    
    var signedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func createUser(firstName: String, lastName: String, email: String, password: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] (result, error) in

            guard let self = self else {
                fatalError("self is nil")
            }
            
            guard error == nil else {
                completionHandler(FirebaseError.auth(error), false)
                return
            }

            guard let result = result else {
                completionHandler(FirebaseError.unknown, false)
                return
            }

            let firstNameKey = UserDataProperty.firstName.rawValue
            let lastNameKey = UserDataProperty.lastName.rawValue
            let uidKey = UserDataProperty.uid.rawValue
            let data = [firstNameKey: firstName, lastNameKey: lastName, uidKey: result.user.uid]
            
            self.database.collection(DBCollectionKey.users.rawValue).document(result.user.uid).setData(data) { error in
                if error != nil {
                    completionHandler(FirebaseError.database(error), false)
                    return
                }
                completionHandler(nil, true)
            }
        }
    }

    func signIn(email: String, password: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in

            guard error == nil else {
                completionHandler(FirebaseError.auth(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    func signOut(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        do {
            try auth.signOut()
        } catch let signOutError {
            completionHandler(FirebaseError.signOut(signOutError), false)
        }
    }
    
    func getCurrentUserData(completionHandler: @escaping (FirebaseError?, Bool, [String: Any]?) -> Void) {
        guard let uid = auth.currentUser?.uid else {
            fatalError("Can't access without logged in user.")
        }
        
        database.collection(DBCollectionKey.users.rawValue).document(uid).getDocument(completion: { document, error in
            guard error == nil else {
                completionHandler(FirebaseError.database(error), false, nil)
                return
            }
            
            guard let document = document else {
                completionHandler(FirebaseError.unknown, false, nil)
                return
            }
                        
            completionHandler(nil, true, document.data())
        })
    }
    
    func addDataToDocument(collection: String, data: [String: Any]) {
        guard let uid = auth.currentUser?.uid else {
            fatalError("Can't access without logged in user.")
        }
        
        database.collection(collection).document(uid).setData(data, merge: true)
    }
}
