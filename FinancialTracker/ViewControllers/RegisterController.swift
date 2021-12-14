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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //warningLabel.adjustsFontSizeToFitWidth = true
        
        setUpNormаlField(firstNameField)
        setUpNormаlField(lastNameField)
        setUpNormаlField(emailField)
        setUpPassField(passwordField)
    }
    
    func setUpNormаlField(_ normal: UITextField) {
        normal.layer.cornerRadius = 15
        normal.layer.borderColor = UIColor.black.cgColor
        normal.layer.borderWidth = 1
    }
    
    func setUpPassField(_ password: UITextField) {
        password.layer.cornerRadius = 15
        password.layer.borderColor = UIColor.black.cgColor
        password.layer.borderWidth = 1
        password.isSecureTextEntry = true
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
            //warningLabel.alpha = 1
            //warningLabel.text = error
        } else {
            guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                guard let result = result else { return }
                
                if error != nil {
                    //self.warningLabel.alpha = 1
                    //self.warningLabel.text = error?.localizedDescription
                } else {
                    let db = Firestore.firestore()
                    
                    db.collection("users").addDocument(data: ["firstName":firstName,
                                                              "lastName":lastName,
                                                              "uid":result.user.uid]) { error in
                        if error != nil {
                            //self.warningLabel.alpha = 1
                            //self.warningLabel.text = "Error storing user."
                        }
                    }
                 
                    self.moveToNextScreen()
                }
            }
        }
    }
    
    func moveToNextScreen() {
        guard let balanceVC = storyboard?.instantiateViewController(withIdentifier: "BalanceVC") as? BalanceController else {
            return
        }
        
        present(balanceVC, animated: true)
    }
    
}
