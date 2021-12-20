//
//  BalanceController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class BalanceViewController: UIViewController {
    @IBOutlet var balanceTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        balanceTextField.keyboardType = .numberPad
                
        FirebaseHandler.shared.getCurrentUserData(completionHandler: { firebaseError, success, data in
            guard success == true else {
                switch firebaseError {
                case .some(let error):
                    fatalError(error.localizedDescription)
                case .none:
                    break
                }

                return
            }
            guard let data = data else {
                return
            }
            
            guard let firstName = data["firstName"] as? String else {
                return
            }
            
            self.welcomeLabel.text = "Welcome " + firstName
        })
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        guard let balance = balanceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !balance.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Balance", message: "Please fill in your starting balance"), animated: true)
            return
        }

        guard Int(balance) != nil else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        FirebaseHandler.shared.addDataToDocument(collection: "users", data: ["balance": balance])
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        FirebaseHandler.shared.signOut { firebaseError, success in
            guard success == true else {
                switch firebaseError {
                case .signOut(let error):
                    guard let error = error else { return }
                    fatalError(error.localizedDescription)
                case .none:
                    break
                default:
                    break
                }
                
                return
            }
        }
        
        guard let entryVC = storyboard?.instantiateViewController(withIdentifier: "EntryVC") as? EntryViewController else {
            fatalError("Couldn't convert to entryVC.")
        }
        
        entryVC.modalPresentationStyle = .fullScreen
        present(entryVC, animated: true)
    }
}
