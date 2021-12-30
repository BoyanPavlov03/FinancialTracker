//
//  ExpenseViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit

enum Category: String, CaseIterable {
    case transport = "Transport"
    case grocery = "Grocery"
    case other = "Other"
}

class ExpenseViewController: UIViewController {
    @IBOutlet var expenseAmountTextField: UITextField!
    @IBOutlet var categoryPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
    }
    
    @IBAction func addExpenseButtonTapped(_ sender: Any) {
        guard let expense = expenseAmountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !expense.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Amount", message: "Please fill in the amount of the expense"), animated: true)
            return
        }
        
        guard let expenseNumber = Int(expense) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        let categoryType = Category.allCases[categoryPicker.selectedRow(inComponent: 0)].rawValue
        
        FirebaseHandler.shared.addExpenseToCurrentUser(expenseNumber, category: categoryType) { firebaseError, _ in
            switch firebaseError {
            case .access:
                self.present(UIAlertController.create(title: "Acess Error", message: "You can't access that"), animated: true)
            case .auth, .database, .unknown, .signOut:
                // swiftlint:disable:next force_unwrapping
                assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                // swiftlint:disable:next unneeded_break_in_switch
                break
            case .none:
                guard let homeVC = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC") as? HomeViewController else {
                    return
                }
                homeVC.modalPresentationStyle = .fullScreen
                self.present(homeVC, animated: true)
            }
        }
    }
    
}

extension ExpenseViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Category.allCases.count
    }
}

extension ExpenseViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Category.allCases[row].rawValue
    }
}
