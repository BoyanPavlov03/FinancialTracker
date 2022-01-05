//
//  BalanceController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class BalanceViewController: UIViewController {
    // MARK: - View properties
    @IBOutlet var balanceTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var welcomeLabel: UILabel!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        balanceTextField.keyboardType = .numberPad
        
        title = "Balance"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        guard let firstName = FirebaseHandler.shared.currentUser?.firstName else {
            assertionFailure("User data is nil")
            return
        }
        
        self.welcomeLabel.text = "Welcome " + firstName
        
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        guard let balance = balanceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !balance.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Balance", message: "Please fill in your starting balance"), animated: true)
            return
        }
        
        guard let balanceNumber = Int(balance) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        FirebaseHandler.shared.addBalanceToCurrentUser(balanceNumber) { firebaseError, _ in
            switch firebaseError {
            case .access(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
            case .auth, .database, .unknown, .signOut:
                // swiftlint:disable:next force_unwrapping
                assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                // swiftlint:disable:next unneeded_break_in_switch
                break
            case .none:
                let navVC = ViewControllerFactory.shared.navController
                let homeVC = ViewControllerFactory.shared.viewController(for: .home)
                navVC.pushViewController(homeVC, animated: true)
                self.view.window?.rootViewController = navVC
                self.view.window?.makeKeyAndVisible()
            }
        }
    }
    
    @objc func signOut() {
        FirebaseHandler.shared.signOut { firebaseError, _ in
            switch firebaseError {
            case .signOut(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Sign Out Error", message: error.localizedDescription), animated: true)
            case .database, .unknown, .access, .auth:
                // swiftlint:disable:next force_unwrapping
                assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                // swiftlint:disable:next unneeded_break_in_switch
                break
            case .none:
                break
            }
        }
    }
    
}
