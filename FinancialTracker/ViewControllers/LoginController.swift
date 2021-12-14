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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //warningLabel.adjustsFontSizeToFitWidth = true
        
        setUpEmailField(emailField)
        setUpPassField(passwordField)
    }
    
    func setUpEmailField(_ email: UITextField) {
        email.layer.cornerRadius = 15
        email.layer.borderColor = UIColor.black.cgColor
        email.layer.borderWidth = 1
    }
    
    func setUpPassField(_ password: UITextField) {
        password.layer.cornerRadius = 15
        password.layer.borderColor = UIColor.black.cgColor
        password.layer.borderWidth = 1
        password.isSecureTextEntry = true
    }
    
    func validate() -> String? {
        
        if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
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
            
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if error != nil {
                    //self.warningLabel.alpha = 1
                    //self.warningLabel.text = error?.localizedDescription
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
