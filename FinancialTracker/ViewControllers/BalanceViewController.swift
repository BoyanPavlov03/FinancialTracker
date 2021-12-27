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
        
        // Data is fetched too slow and this crashes. Will be used in the future
        /*
        guard let firstName = FirebaseHandler.shared.currentUser?.firstName else {
            assertionFailure("User data is nil")
            return
        }
        
        self.welcomeLabel.text = "Welcome " + firstName
         */
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
            case .access:
                self.present(UIAlertController.create(title: "Acess Error", message: "You can't access that"), animated: true)
            case .auth, .database, .unknown, .signOut:
                assertionFailure("This error should not appear.")
                break
            case .none:
                assert(true)
                break
            }
        }
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        FirebaseHandler.shared.signOut { firebaseError, _ in
            switch firebaseError {
            case .signOut(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Sign Out Error", message: error.localizedDescription), animated: true)
            case .database, .unknown, .access, .auth:
                assertionFailure("This error should not appear.")
                break
            case .none:
                assert(true)
                break
            }
        }
    }
}
