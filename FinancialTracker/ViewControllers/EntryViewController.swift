//
//  ViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

class EntryViewController: UIViewController {
    // MARK: - View properties
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Entry"
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    @IBAction func logInButtonTapped(_ sender: Any) {
        let loginVC = ViewControllerFactory.viewController(for: .login)
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        let registerVC = ViewControllerFactory.viewController(for: .register)
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
}
