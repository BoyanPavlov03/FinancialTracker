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
        
        guard emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return "Fill in email."
        }
        
        guard passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return "Fill in password."
        }
        
        return nil
    }
    
    
    @IBAction func registerTapped(_ sender: Any) {
        let error = validate()
        let ac = UIAlertController(title: "Error", message: "", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Continue", style: .default))
        
        if error != nil {
            ac.message = error
            present(ac, animated: true)
        } else {
            guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                fatalError("Couldn't process email.")
            }
            guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {                 fatalError("Couldn't process password.")
            }
            
            Firebase.signIn(email: email, password: password) { (err) in
                if err != nil {
                    ac.message = err
                    self.present(ac, animated: true)
                } else {
                    self.successfullAuth()
                }
            }
        }
    }
    
    func successfullAuth() {
        guard let balanceVC = storyboard?.instantiateViewController(withIdentifier: "BalanceVC") as? BalanceController else {
            fatalError("Couldn't convert to balanceVC.")
        }
        balanceVC.modalPresentationStyle = .fullScreen
        present(balanceVC, animated: true)
    }

}
