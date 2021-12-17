//
//  BalanceController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class BalanceController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func SignOutTapped(_ sender: Any) {
        Firebase.signOut()
        guard let entryVC = storyboard?.instantiateViewController(withIdentifier: "EntryVC") as? EntryController else {
            fatalError("Couldn't convert to entryVC.")
        }
        
        entryVC.modalPresentationStyle = .fullScreen
        present(entryVC, animated: true)
    }
}
