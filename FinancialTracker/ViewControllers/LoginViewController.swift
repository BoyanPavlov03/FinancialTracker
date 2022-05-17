//
//  LoginController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class LoginViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var logoImage: UIImageView!
    
    // MARK: - Properties
    var authManager: AuthManager?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Login"
        self.navigationItem.hidesBackButton = true
        
        setUpUITextField(emailField)
        setUpUITextField(passwordField)
        passwordField.isSecureTextEntry = true
        loginButton.layer.cornerRadius = 15
        
        let keyboardRemovalGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(keyboardRemovalGesture)
        
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            logoImage.image = UIImage(named: "logoWhite")
            passwordField.layer.borderColor = UIColor.black.cgColor
            emailField.layer.borderColor = UIColor.black.cgColor
        case .dark:
            logoImage.image = UIImage(named: "logoDark")
            passwordField.layer.borderColor = UIColor.white.cgColor
            emailField.layer.borderColor = UIColor.white.cgColor
        @unknown default:
            fatalError("Unknown style")
        }
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        switch newCollection.userInterfaceStyle {
        case .dark:
            logoImage.image = UIImage(named: "logoDark")
            passwordField.layer.borderColor = UIColor.white.cgColor
            emailField.layer.borderColor = UIColor.white.cgColor
        case .light, .unspecified:
            logoImage.image = UIImage(named: "logoWhite")
            passwordField.layer.borderColor = UIColor.black.cgColor
            emailField.layer.borderColor = UIColor.black.cgColor
        @unknown default:
            fatalError("Unknown style")
        }
    }
    
    // MARK: - Own methods
    private func setUpUITextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 15
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
    }
    
    // MARK: - IBAction methods
    @IBAction func loginButtonTapped() {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            present(UIAlertController.create(title: "Missing Email", message: "Please fill in your email"), animated: true)
            return
        }
        
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else {
            present(UIAlertController.create(title: "Missing Password", message: "Please fill in your password"), animated: true)
            return
        }

        authManager?.logInUser(email: email, password: password) { authError, user in
            guard user != nil else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
        }
    }
    
    @IBAction func registerScreenButtonTapped(_ sender: Any) {
        guard let registerVC = ViewControllerFactory.shared.viewController(for: .register) as? RegisterViewController else {
            assertionFailure("Couldn't parse to RegisterViewController.")
            return
        }
        
        registerVC.authManager = authManager
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = textField.superview?.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginButtonTapped()
            return true
        }
        return false
    }
}
