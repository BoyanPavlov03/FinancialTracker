//
//  Firebase.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 15.12.21.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct Firebase {
    static func createUser(firstName: String, lastName: String, email: String, password: String, errorHandler: @escaping (String?) -> ()) {
        errorHandler(nil)
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                    
            guard let result = result else {
                fatalError("errorHere")
            }
                        
            if error != nil {
                errorHandler(error?.localizedDescription)
            } else {
                let db = Firestore.firestore()
                                
                db.collection("users").addDocument(data: ["firstName":firstName,"lastName":lastName,"uid":result.user.uid]) { error in
                    if error != nil {
                        errorHandler("Error storing user.")
                    }
                }
            }
        }
    }
    
    static func signIn(email: String, password: String, errorHandler: @escaping (String?) -> ()) {
        errorHandler(nil)
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
                        
            if error != nil {
                errorHandler(error?.localizedDescription)
            }
        }
    }
}
