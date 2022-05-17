//
//  ExpenseViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit

class TransactionViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var expenseOrIncomeSegmentedControl: UISegmentedControl!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var dateTextField: UITextField!
    
    // MARK: - Private properties
    private var categoryCases: [Category] {
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil.")
        }
        
        // If control is on 0 it should expense categories that are shown
        // and if on 1 - income ones
        if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
            var categories: [ExpenseCategory] = [.grocery, .transport]
            categories.append(contentsOf: currentUser.premium ? [.taxes, .travel, .utility, .other] : [.other])
            return categories
        } else {
            var categories: [IncomeCategory] = [.salary, .items]
            categories.append(contentsOf: currentUser.premium ? [.interest, .government, .other] : [.other])
            return categories
        }
    }
    
    // MARK: - Properties
    var authManager: AuthManager?
    let datePicker = UIDatePicker()
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Transaction"
        
        amountTextField.delegate = self
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        addButton.layer.cornerRadius = 15
        
        let keyboardRemovalGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(keyboardRemovalGesture)
        
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChange(datePicker:)), for: UIControl.Event.valueChanged)
        datePicker.preferredDatePickerStyle = .inline
        datePicker.maximumDate = Date()
        
        dateTextField.inputView = datePicker
        dateTextField.text = Date().formatDate("MMMM dd yyyy")
    }
    
    // MARK: - IBAction methods
    @IBAction func expenseOrIncomeSegmentedControlTapped(_ sender: UISegmentedControl) {
        categoryPicker.reloadAllComponents()
    }
    
    @IBAction func addTransactionButtonTapped(_ sender: Any) {
        guard let amount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !amount.isEmpty else {
            present(UIAlertController.create(title: "Missing Amount", message: "Please fill in the amount."), animated: true)
            return
        }
        
        let amountNumber = amount.doubleValue
        
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil.")
        }
        
        let selectedCategory = categoryCases[categoryPicker.selectedRow(inComponent: 0)]
        
        let uid = currentUser.uid
        let date = datePicker.date
        authManager?.addTransactionToUserByUID(uid, amount: amountNumber, category: selectedCategory, date: date) { authError, success in
            guard success else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func dateChange(datePicker: UIDatePicker) {
        dateTextField.text = datePicker.date.formatDate("MMMM dd yyyy")
    }
}

// MARK: - UIPickerViewDataSource
extension TransactionViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryCases.count
    }
}

// MARK: - UIPickerViewDelegate
extension TransactionViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let expense = categoryCases as? [ExpenseCategory] {
            return expense[row].rawValue
        } else if let income = categoryCases as? [IncomeCategory] {
            return income[row].rawValue
        }
        return ""
    }
}

extension TransactionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return false
        }
        
        if newString.doubleValue < 0 && !newString.isEmpty {
            return false
        }
        
        let arrayOfString = newString.components(separatedBy: ".")

        if arrayOfString.count > 2 {
            return false
        }
        
        guard let currency = authManager?.currentUser?.currency else {
            fatalError("User data is nil")
        }
        
        if arrayOfString.count > 1 && arrayOfString[1].count > currency.symbolsAfterComma {
            return false
        }

        return true
    }
}
