//
//  LoginController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginController: UIViewController {
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var warningLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passwordField.isSecureTextEntry = true
        warningLabel.adjustsFontSizeToFitWidth = true
    }
    
    func validate() -> String? {
        
        if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Fill in all fields."
        }
        
        /*let password = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if passwordValidation(password) == false {
            return "Make sure your password is at least 8 characters, contains a special character and a number."
        }
        
        let email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if emailValidation(email) == false {
            return "Make sure your email is valid."
        }*/
        
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
            
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if error != nil {
                    self.warningLabel.alpha = 1
                    self.warningLabel.text = error?.localizedDescription
                } else {
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
