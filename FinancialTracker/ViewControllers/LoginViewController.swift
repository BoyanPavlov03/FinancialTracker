//
//  LoginController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

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

        FirebaseHandler.shared.signIn(email: email, password: password) { firebaseError, success in
            guard success == true else {
                switch firebaseError {
                case .auth(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Auth Error", message: error.localizedDescription), animated: true)
                case .none:
                    break
                default:
                    break
                }
                
                return
            }
            
            guard let balanceVC = self.storyboard?.instantiateViewController(withIdentifier: "BalanceVC") as? BalanceViewController else {
                fatalError("Couldn't convert to balanceVC.")
            }
            balanceVC.modalPresentationStyle = .fullScreen
            self.present(balanceVC, animated: true)
        }
    }
}
