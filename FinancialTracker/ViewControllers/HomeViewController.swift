//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
        
    @IBAction func addButtonTapped(_ sender: Any) {
        guard let expenseVC = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseVC") as? ExpenseViewController else {
            return
        }
        
        expenseVC.modalPresentationStyle = .fullScreen
        present(expenseVC, animated: true)
    }
}
