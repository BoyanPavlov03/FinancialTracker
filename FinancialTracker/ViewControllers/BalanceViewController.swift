//
//  BalanceController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class BalanceViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var balanceTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var currencyPicker: UIPickerView!
    
    // MARK: - Private properties
    private var currencies: [Currency] = [] {
        didSet {
            DispatchQueue.main.async {
                self.currencyPicker.reloadAllComponents()
            }
        }
    }
    // MARK: - Properties
    var authManager: AuthManager?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Balance"
        navigationItem.setHidesBackButton(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil")
        }
        
        welcomeLabel.text = "Welcome " + currentUser.firstName
        
        Currency.getCurrencies { error, currencies in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            }
            
            guard let currencies = currencies else {
                assertionFailure("Data is missing.")
                return
            }

            self.currencies = currencies
        }
        
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        nextButton.layer.cornerRadius = 15
        balanceTextField.delegate = self
    }
    
    // MARK: - IBAction methods
    @IBAction func nextButtonTapped(_ sender: Any) {
        guard let balance = balanceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !balance.isEmpty else {
            present(UIAlertController.create(title: "Missing Balance", message: "Please fill in your starting balance"), animated: true)
            return
        }
        
        let balanceNumber = balance.doubleValue

        let selectedCurrency = currencies[currencyPicker.selectedRow(inComponent: 0)]
        
        authManager?.addBalanceToCurrentUser(balanceNumber, currency: selectedCurrency) { authError, success in
            guard success else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
            
            guard let tabBarVC = ViewControllerFactory.shared.viewController(for: .tabBar) as? TabBarController else {
                assertionFailure("Couldn't parse to TabBarController.")
                return
            }
            
            guard let authManager = self.authManager else { return }
            
            tabBarVC.setAuthManager(authManager, accountCreated: true)
            self.view.window?.rootViewController = tabBarVC
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    @objc private func signOut() {
        let alertController = UIAlertController(title: "Sign Out", message: "You are about to sign out. Are you sure?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            self.authManager?.signOut { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."
                    
                    self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
}

// MARK: - UIPickerViewDelegate
extension BalanceViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row].code
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let balance = balanceTextField.text else {
            assertionFailure("Not value.")
            return
        }
        
        let arrayOfString = balance.components(separatedBy: ".")
        let selectedCurrency = currencies[row]
        
        if arrayOfString.count > 1 && arrayOfString[1].count > selectedCurrency.symbolsAfterComma {
            var amount = arrayOfString[1].count - selectedCurrency.symbolsAfterComma
            var newString = balance.removeLastCharacters(amount: &amount)
            if selectedCurrency.symbolsAfterComma == 0 {
                newString.removeLast()
            }
            
            balanceTextField.text = newString
        }
        
    }
}

// MARK: - UIPickerViewDataSource
extension BalanceViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
}

extension BalanceViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return false
        }
        
        let selectedCurrency = currencies[currencyPicker.selectedRow(inComponent: 0)]
        let arrayOfString = newString.components(separatedBy: ".")
        
        // If the currency the user holds on to at the moment is one with 0 digits after the comma/dot, a comma/dot should not be allowed to be written
        if selectedCurrency.symbolsAfterComma == 0 && (newString.last == "." || newString.last == ",") {
            return false
        }
        
        // If the entered text is not a whole number the user text isn't written onto the field
        if newString.doubleValue < 0 && !newString.isEmpty {
            return false
        }
                
        // Checking if user has reached the currency limit after the comma/dot
        if arrayOfString.count > 1 && arrayOfString[1].count > selectedCurrency.symbolsAfterComma {
            return false
        }

        return true
    }
}
