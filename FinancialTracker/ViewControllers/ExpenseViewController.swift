//
//  ExpenseViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit

class ExpenseViewController: UIViewController {
    @IBOutlet var expenseAmountTextField: UITextField!
    @IBOutlet var categoryPicker: UIPickerView!
            
    var authManager: AuthManager?
    var categoryCases: [Category] {
        guard let premium = authManager?.currentUser?.premium else {
            assertionFailure("User data is nil.")
            return []
        }
        var categories: [Category] = [.grocery, .transport]
        
        categories.append(contentsOf: premium ? [.taxes, .travel, .utility, .other] : [.other])
        
        return categories
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Expense"
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
    }
    
    @IBAction func addExpenseButtonTapped(_ sender: Any) {
        guard let expense = expenseAmountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !expense.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Amount", message: "Please fill in the amount of the expense"), animated: true)
            return
        }
        
        guard let expenseNumber = Double(expense) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        let selectedCategory = categoryCases[categoryPicker.selectedRow(inComponent: 0)]
        
        authManager?.addExpenseToCurrentUser(expenseNumber, category: selectedCategory) { firebaseError, _ in
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
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension ExpenseViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryCases.count
    }
}

extension ExpenseViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryCases[row].rawValue
    }
}
