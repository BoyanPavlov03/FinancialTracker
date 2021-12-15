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
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validate() -> String? {
        
        guard firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return "Fill in first name."
        }
        
        guard lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return "Fill in last name."
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), email != "" else {
            return "Fill in email."
        }
        
        guard passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return "Fill in password."
        }
        
        if isValidEmail(email) == false {
            return "Invalid email format."
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
            guard let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {                 fatalError("Couldn't process first name.")
            }
            guard let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {                 fatalError("Couldn't process last name.")
            }
            
            Firebase.createUser(firstName: firstName, lastName: lastName, email: email, password: password) { (err) in
                if err != nil {
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
