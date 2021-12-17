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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        balanceTextField.keyboardType = .numberPad
    }
    @IBAction func nextButtonTapped(_ sender: Any) {
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        FirebaseHandler.shared.signOut()
        guard let entryVC = storyboard?.instantiateViewController(withIdentifier: "EntryVC") as? EntryViewController else {
            fatalError("Couldn't convert to entryVC.")
        }
        
        entryVC.modalPresentationStyle = .fullScreen
        present(entryVC, animated: true)
    }
}
