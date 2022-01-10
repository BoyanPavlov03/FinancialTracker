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
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Login"
        
        setUpUITextField(emailField)
        setUpUITextField(passwordField)
        passwordField.isSecureTextEntry = true
    }
    
    func setUpUITextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 15
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
    }
    
    @IBAction func loginButtonTapped(_: Any) {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Email", message: "Please fill in your email"), animated: true)
            return
        }
        
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Password", message: "Please fill in your password"), animated: true)
            return
        }
        
        FirebaseHandler.shared.logInUser(email: email, password: password) { firebaseError, _ in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .auth(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Auth Error", message: error.localizedDescription), animated: true)
                case .unknown:
                    self.present(UIAlertController.create(title: "Unknown Error", message: "Unknown"), animated: true)
                case .access(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
                case .database(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
                case .signOut:
                    assertionFailure("This error should not appear: \(firebaseError.localizedDescription)")
                    // swiftlint:disable:next unneeded_break_in_switch
                    break
                }
            }
        }
    }
}
