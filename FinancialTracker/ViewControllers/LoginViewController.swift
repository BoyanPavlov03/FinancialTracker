//
//  LoginController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class LoginViewController: UIViewController {
    // MARK: - View properties
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    var authManager: AuthManager?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Login"
        
        setUpUITextField(emailField)
        setUpUITextField(passwordField)
        passwordField.isSecureTextEntry = true
    }
    
    private func setUpUITextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 15
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
    }
    
    @IBAction func loginButtonTapped(_: Any) {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            present(UIAlertController.create(title: "Missing Email", message: "Please fill in your email"), animated: true)
            return
        }
        
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else {
            present(UIAlertController.create(title: "Missing Password", message: "Please fill in your password"), animated: true)
            return
        }
        authManager?.logInUser(email: email, password: password) { authError, _ in
            if let alert = UIAlertController.create(basedOnAuthError: authError) {
                self.present(alert, animated: true)
                return
            }
        }
    }
}
