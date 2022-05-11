//
//  RegisterController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

class RegisterViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var logoImage: UIImageView!
    
    // MARK: - Properties
    var authManager: AuthManager?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Register"
        self.navigationItem.hidesBackButton = true
        
        setUpUITextField(firstNameField)
        setUpUITextField(lastNameField)
        setUpUITextField(emailField)
        setUpUITextField(passwordField)
        passwordField.isSecureTextEntry = true
        registerButton.layer.cornerRadius = 15
        
        switch traitCollection.userInterfaceStyle {
        case .dark:
            logoImage.image = UIImage(named: "logoDark")
            setBorderColor(color: UIColor.white.cgColor)
        case .light, .unspecified:
            logoImage.image = UIImage(named: "logoWhite")
            setBorderColor(color: UIColor.black.cgColor)
        @unknown default:
            fatalError("Unknown style")
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        switch newCollection.userInterfaceStyle {
        case .dark:
            logoImage.image = UIImage(named: "logoDark")
            setBorderColor(color: UIColor.white.cgColor)
        case .light, .unspecified:
            logoImage.image = UIImage(named: "logoWhite")
            setBorderColor(color: UIColor.black.cgColor)
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
    
    private func setBorderColor(color: CGColor) {
        passwordField.layer.borderColor = color
        emailField.layer.borderColor = color
        firstNameField.layer.borderColor = color
        lastNameField.layer.borderColor = color
    }
    
    // MARK: - IBAction methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @IBAction func registerButtonTapped(_: Any) {
        guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty else {
            present(UIAlertController.create(title: "Missing First Name", message: "Please fill in your first name"), animated: true)
            return
        }
        
        guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty else {
            present(UIAlertController.create(title: "Missing Password", message: "Please fill in your last name"), animated: true)
            return
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            present(UIAlertController.create(title: "Missing Email", message: "Please fill in your email"), animated: true)
            return
        }
        
        guard let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else {
            present(UIAlertController.create(title: "Missing Password", message: "Please fill in your password"), animated: true)
            return
        }
        
        if isValidEmail(email) == false {
            present(UIAlertController.create(title: "Email Format", message: "Invalid email format"), animated: true)
            return
        }
        
        authManager?.registerUser(firstName: firstName, lastName: lastName, email: email, password: password) { authError, user in
            guard user != nil else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
        }
    }
    
    @IBAction func loginScreenButtonTapped(_ sender: Any) {
        guard let loginVC = ViewControllerFactory.shared.viewController(for: .login) as? LoginViewController else {
            assertionFailure("Couldn't parse to LoginViewController.")
            return
        }
        
        loginVC.authManager = authManager
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
}
