//
//  CurrencyTableViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 23.01.22.
//

import UIKit

class CurrencyTableViewController: UITableViewController {
    private var currencies: [Currency] = []
    
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Currency"
        self.tabBarItem.image = UIImage(systemName: "dollarsign.circle")
        
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
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Currency", for: indexPath)

        cell.textLabel?.text = "\(currencies[indexPath.row].code) (\(currencies[indexPath.row].name))"
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = authManager?.currentUser, let currency = user.currency else {
            assertionFailure("User data is nil")
            return
        }
        
        let selectedCode = currencies[indexPath.row].code
        
        if selectedCode == currency.code {
            let alertVC = UIAlertController.create(title: "Owned", message: "Your current currency is the same.")
            present(alertVC, animated: true)
            return
        }
        
        let message = "You are about to change your current currency to \(selectedCode)"
        let alertVC = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "Change", style: .default, handler: { _ in
            self.authManager?.changeCurrentUserCurrency(self.currencies[indexPath.row]) { firebaseError, _ in
                if let firebaseError = firebaseError {
                    assertionFailure(firebaseError.localizedDescription)
                    return
                }
                
                self.navigationController?.popViewController(animated: true)
            }
        }))
        
        present(alertVC, animated: true)
    }
}
