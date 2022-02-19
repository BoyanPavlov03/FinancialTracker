//
//  ExpenseViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit

class TransactionViewController: UIViewController {
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var expenseOrIncomeSegmentedControl: UISegmentedControl!
    
    var authManager: AuthManager?
    var categoryCases: [Category] {
        guard let premium = authManager?.currentUser?.premium else {
            assertionFailure("User data is nil.")
            return []
        }
        
        if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
            var categories: [ExpenseCategory] = [.grocery, .transport]
            categories.append(contentsOf: premium ? [.taxes, .travel, .utility, .other] : [.other])
            return categories
        } else {
            var categories: [IncomeCategory] = [.salary, .items]
            categories.append(contentsOf: premium ? [.interest, .government, .other] : [.other])
            return categories
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Transaction"
        let requestOrSendButton = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(requestOrSend))
        self.navigationItem.rightBarButtonItem = requestOrSendButton
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
    }
    
    @objc func requestOrSend() {
        guard let sendVC = ViewControllerFactory.shared.viewController(for: .requestOrSend) as? RequestOrSendViewController else {
            assertionFailure("Couldn't cast to RequestOrSendViewController.")
            return
        }
        sendVC.authManager = authManager
        sendVC.type = TransferType(rawValue: self.navigationItem.rightBarButtonItem?.title ?? "Send")
        if let items = self.tabBarController?.tabBar.items {
            for item in items {
                item.isEnabled = false
            }
        }
        sendVC.delegate = self
        present(sendVC, animated: true)
    }
    
    @IBAction func expenseOrIncomeSegmentedControlTapped(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case TransferType.send.index:
            self.navigationItem.rightBarButtonItem?.title = TransferType.send.rawValue
        case TransferType.request.index:
            self.navigationItem.rightBarButtonItem?.title = TransferType.request.rawValue
        default:
            break
        }
        categoryPicker.reloadAllComponents()
    }
    
    @IBAction func addTransactionButtonTapped(_ sender: Any) {
        guard let amount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !amount.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Amount", message: "Please fill in the amount."), animated: true)
            return
        }
        
        guard let amountNumber = Double(amount) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        let selectedCategory = categoryCases[categoryPicker.selectedRow(inComponent: 0)]
        
        authManager?.addTransactionToUserByUID(amountNumber, category: selectedCategory) { firebaseError, _ in
            switch firebaseError {
            case .access(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
            case .auth, .database, .unknown, .signOut, .nonExistingUser:
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

extension TransactionViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryCases.count
    }
}

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

extension TransactionViewController: RequestOrSendViewControllerDelegate {
    func requestOrSendVIewControllerShowTabBar(sender: RequestOrSendViewController) {
        DispatchQueue.main.async {
            if let items = self.tabBarController?.tabBar.items {
                for item in items {
                    item.isEnabled = true
                }
            }
        }
    }
}
