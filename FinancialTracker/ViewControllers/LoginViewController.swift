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
            if let authError = authError {
                switch authError {
                case .auth(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Auth Error", message: error.localizedDescription), animated: true)
                case .unknown:
                    self.present(UIAlertController.create(title: "Unknown Error", message: authError.localizedDescription), animated: true)
                case .database(let error):
                    if let databaseError = error {
                        switch databaseError {
                        case .database(let error):
                            guard let error = error else { return }
                            self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
                        case .access(let error):
                            guard let error = error else { return }
                            self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
                        case .unknown:
                            self.present(UIAlertController.create(title: "Unknown Error", message: "Unknown"), animated: true)
                        default:
                            assertionFailure("This databaseError should not appear: \(databaseError.localizedDescription)")
                            return
                        }
                    }
                default:
                    assertionFailure("This authError should not appear: \(authError.localizedDescription)")
                    return
                }
            }
        }
    }
}
