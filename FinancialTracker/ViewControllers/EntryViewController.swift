//
//  ViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

class EntryViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    
    // MARK: - Properties
    var authManager: AuthManager?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Entry"
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
    // MARK: - IBAction methods
    @IBAction func logInButtonTapped(_ sender: Any) {
        guard let loginVC = ViewControllerFactory.shared.viewController(for: .login) as? LoginViewController else {
            assertionFailure("Couldn't parse to LoginViewController.")
            return
        }
        loginVC.authManager = authManager
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let registerVC = ViewControllerFactory.shared.viewController(for: .register) as? RegisterViewController else {
            assertionFailure("Couldn't parse to RegisterViewController.")
            return
        }
        registerVC.authManager = authManager
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
}
