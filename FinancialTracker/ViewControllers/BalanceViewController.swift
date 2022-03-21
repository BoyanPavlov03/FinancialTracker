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
        balanceTextField.keyboardType = .numberPad
        
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
    }
    
    // MARK: - IBAction methods
    @IBAction func nextButtonTapped(_ sender: Any) {
        guard let balance = balanceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !balance.isEmpty else {
            present(UIAlertController.create(title: "Missing Balance", message: "Please fill in your starting balance"), animated: true)
            return
        }
        
        guard let balanceNumber = Double(balance) else {
            present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
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
