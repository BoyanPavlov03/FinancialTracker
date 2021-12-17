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
    case db(Error?)
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
    private let db = Firestore.firestore()
    static let shared = FirebaseHandler()
    
    private init() {}
    
    var signedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func createUser(firstName: String, lastName: String, email: String, password: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in

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

            self.db.collection(DBCollectionKey.users.rawValue).addDocument(data: [UserDataProperty.firstName.rawValue: firstName, UserDataProperty.lastName.rawValue: lastName, UserDataProperty.uid.rawValue: result.user.uid]) { error in
                if error != nil {
                    completionHandler(FirebaseError.db(error), false)
                    return
                }
                completionHandler(nil, true)
            }
        }
    }

    func signIn(email: String, password: String, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in

            if error != nil {
                completionHandler(FirebaseError.auth(error), false)
            }
            completionHandler(nil, true)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Error signing out: %@", FirebaseError.signOut(signOutError))
        }
    }
}
