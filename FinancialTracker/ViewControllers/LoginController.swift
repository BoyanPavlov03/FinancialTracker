//
//  LoginController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit
import FirebaseAuth

class LoginController: UIViewController {
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

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

    @IBAction func loginButtonTapped(_: Any) {
        var error: String?

        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            fatalError("Couldn't process email.")
        }
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { fatalError("Couldn't process password.")
        }

        switch "" {
        case email:
            error = "Fill in email."
        case password:
            error = "Fill in password."
        default:
            error = nil
        }

        guard error == nil else {
            let ac = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Continue", style: .default))
            present(ac, animated: true)
            return
        }

        Firebase.signIn(email: email, password: password) { error in
            guard error == nil else {
                let ac = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Continue", style: .default))
                self.present(ac, animated: true)
                return
            }
            self.successfullAuth()
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
