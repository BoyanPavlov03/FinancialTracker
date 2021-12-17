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

struct Firebase {
    static func createUser(firstName: String, lastName: String, email: String, password: String, errorHandler: @escaping (String?) -> Void) {
        errorHandler(nil)

        Auth.auth().createUser(withEmail: email, password: password) { result, error in

            guard error == nil else {
                errorHandler(error?.localizedDescription)
                return
            }

            let db = Firestore.firestore()

            guard let result = result else {
                fatalError("errorHere")
            }

            db.collection("users").addDocument(data: ["firstName": firstName, "lastName": lastName, "uid": result.user.uid]) { error in
                if error != nil {
                    errorHandler("Error storing user.")
                }
            }
        }
    }

    static func signIn(email: String, password: String, errorHandler: @escaping (String?) -> Void) {
        errorHandler(nil)

        Auth.auth().signIn(withEmail: email, password: password) { _, error in

            if error != nil {
                errorHandler(error?.localizedDescription)
            }
        }
    }
    
    static func signedIn() -> Bool {
        return Auth.auth().currentUser != nil ? true : false
    }
    
    static func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
