//
//  RegisterController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

class RegisterController: UIViewController {
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

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

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @IBAction func registerButtonTapped(_: Any) {
        var error: String?

        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            fatalError("Couldn't process email.")
        }
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { fatalError("Couldn't process password.")
        }
        guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { fatalError("Couldn't process first name.")
        }
        guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { fatalError("Couldn't process last name.")
        }

        switch "" {
        case firstName:
            error = "Fill in first name."
        case lastName:
            error = "Fill in last name."
        case email:
            error = "Fill in email."
        case password:
            error = "Fill in password."
        default:
            error = nil
        }

        if isValidEmail(email) == false, error == nil {
            error = "Invalid email format."
        }

        let ac = UIAlertController(title: "Error", message: "", preferredStyle: .alert)

        ac.addAction(UIAlertAction(title: "Continue", style: .default))

        if error != nil {
            ac.message = error
            present(ac, animated: true)
        } else {
            Firebase.createUser(firstName: firstName, lastName: lastName, email: email, password: password) { error in
                if error != nil {
                    self.present(ac, animated: true)
                } else {
                    guard let balanceVC = self.storyboard?.instantiateViewController(withIdentifier: "BalanceVC") as? BalanceController else {
                        fatalError("Couldn't convert to balanceVC.")
                    }
                    balanceVC.modalPresentationStyle = .fullScreen

                    self.present(balanceVC, animated: true)
                }
            }
        }
    }
}
