//
//  BalanceController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 11.12.21.
//

import UIKit

class BalanceViewController: UIViewController {
    // MARK: - View properties
    @IBOutlet var balanceTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var currencyPicker: UIPickerView!
    
    // MARK: - Properties
    private var currencies: [Currency] = []
    var databaseManager: DatabaseManager?
    var authManager: AuthManager?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        balanceTextField.keyboardType = .numberPad
        
        title = "Balance"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        guard let firstName = databaseManager?.currentUser?.firstName else {
            assertionFailure("User data is nil")
            return
        }
        
        self.welcomeLabel.text = "Welcome " + firstName
        
        Currency.getCurrencies { error, currencies in
            if let error = error {
                assertionFailure(error)
                return
            }
            
            guard let currencies = currencies else {
                return
            }

            self.currencies = currencies
            DispatchQueue.main.async {
                self.currencyPicker.reloadAllComponents()
            }
        }
        
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        guard let balance = balanceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !balance.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Balance", message: "Please fill in your starting balance"), animated: true)
            return
        }
        
        guard let balanceNumber = Double(balance) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            return
        }
        
        let selectedCurrency = currencies[currencyPicker.selectedRow(inComponent: 0)]
        
        databaseManager?.addBalanceToCurrentUser(balanceNumber, currency: selectedCurrency) { firebaseError, _ in
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
                guard let tabBarVC = ViewControllerFactory.shared.viewController(for: .tabBar) as? TabBarController else {
                    assertionFailure("Couldn't parse to TabBarController.")
                    return
                }
                
                guard let authManager = self.authManager, let databaseManager = self.databaseManager else { return }
                
                tabBarVC.setAuthManager(authManager)
                tabBarVC.setDatabaseManager(databaseManager)
                self.view.window?.rootViewController = tabBarVC
                self.view.window?.makeKeyAndVisible()
            }
        }
    }
    
    @objc func signOut() {
        authManager?.signOut { firebaseError, _ in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .signOut(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Sign Out Error", message: error.localizedDescription), animated: true)
                case .database, .unknown, .access, .auth:
                    assertionFailure("This error should not appear: \(firebaseError.localizedDescription)")
                    // swiftlint:disable:next unneeded_break_in_switch
                    break
                }
            }
        }
    }
}

extension BalanceViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row].code
    }
}

extension BalanceViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
}
