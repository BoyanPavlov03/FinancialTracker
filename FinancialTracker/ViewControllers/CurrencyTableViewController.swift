//
//  CurrencyTableViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 23.01.22.
//

import UIKit

class CurrencyTableViewController: UITableViewController {
    let currencies = Currencies()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Currency"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        self.tabBarItem.image = UIImage(systemName: "dollarsign.circle")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.allCurrencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Currency", for: indexPath)

        cell.textLabel?.text = "\(currencies.allCurrencies[indexPath.row].code) (\(currencies.allCurrencies[indexPath.row].name))"
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = FirebaseHandler.shared.currentUser, let currency = user.currency else {
            assertionFailure("User data is nil")
            return
        }
        
        let selectedCode = currencies.allCurrencies[indexPath.row].code
        
        if selectedCode == currency.code {
            let alertVC = UIAlertController.create(title: "Owned", message: "You current currency is the same.")
            present(alertVC, animated: true)
            return
        }
        
        let message = "You are about to change your current currency to \(selectedCode)"
        let alertVC = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "Change", style: .default, handler: { _ in
            FirebaseHandler.shared.changeCurrency(self.currencies.allCurrencies[indexPath.row]) { firebaseError, _ in
                if let firebaseError = firebaseError {
                    assertionFailure(firebaseError.localizedDescription)
                }
            }
        }))
        
        present(alertVC, animated: true)
    }

    @objc func signOut() {
        FirebaseHandler.shared.signOut { firebaseError, _ in
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
