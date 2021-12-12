//
//  RegisterController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class RegisterController: UIViewController {
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var warningLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordField.isSecureTextEntry = true
        warningLabel.adjustsFontSizeToFitWidth = true
    }
    
    func validate() -> String? {
        
        if firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Fill in all fields."
        }
        
        return nil
    }
    
    
    @IBAction func registerTapped(_ sender: Any) {
        let error = validate()
        
        if error != nil {
            warningLabel.alpha = 1
            warningLabel.text = error
        } else {
            guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                guard let result = result else { return }
                
                if error != nil {
                    self.warningLabel.alpha = 1
                    self.warningLabel.text = error?.localizedDescription
                } else {
                    let db = Firestore.firestore()
                    
                    db.collection("users").addDocument(data: ["firstName":firstName,
                                                              "lastName":lastName,
                                                              "uid":result.user.uid]) { error in
                        if error != nil {
                            self.warningLabel.alpha = 1
                            self.warningLabel.text = "Error storing user."
                        }
                    }
                 
                    self.moveToNextScreen()
                }
            }
        }
    }
    
    func moveToNextScreen() {
        let balanceVC = storyboard?.instantiateViewController(withIdentifier: "BalanceVC") as? BalanceController
        
        view.window?.rootViewController = balanceVC
        view.window?.makeKeyAndVisible()
    }
    
}
