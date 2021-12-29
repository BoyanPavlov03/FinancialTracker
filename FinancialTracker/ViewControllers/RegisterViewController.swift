//
//  RegisterController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

class RegisterViewController: UIViewController {
    // MARK: - View properties
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var registerButton: UIButton!

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUITextField(firstNameField)
        setUpUITextField(lastNameField)
        setUpUITextField(emailField)
        setUpUITextField(passwordField)
        passwordField.isSecureTextEntry = true
    }

    private func setUpUITextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 15
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @IBAction func registerButtonTapped(_: Any) {
        guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty else {
            self.present(UIAlertController.create(title: "Missing First Name", message: "Please fill in your first name"), animated: true)
            return
        }
        
        guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Password", message: "Please fill in your last name"), animated: true)
            return
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Email", message: "Please fill in your email"), animated: true)
            return
        }
        
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Password", message: "Please fill in your password"), animated: true)
            return
        }

        if isValidEmail(email) == false {
            self.present(UIAlertController.create(title: "Email Format", message: "Invalid email format"), animated: true)
            return
        }

        FirebaseHandler.shared.registerUser(firstName: firstName, lastName: lastName, email: email, password: password) { firebaseError, _ in
            
            switch firebaseError {
            case .unknown:
                self.present(UIAlertController.create(title: "Unknown Error", message: "Unknown"), animated: true)
            case .auth(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Auth Error", message: error.localizedDescription), animated: true)
            case .database(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
            case .access, .signOut, .none:
                // swiftlint:disable:next force_unwrapping
                assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                // swiftlint:disable:next unneeded_break_in_switch
                break
            }
        }
    }
}
