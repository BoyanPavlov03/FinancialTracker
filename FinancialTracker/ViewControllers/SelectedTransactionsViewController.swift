//
//  SelectedTransactionsViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 1.05.22.
//

import UIKit

class SelectedTransactionsViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var transactionTableView: UITableView!
    
    // MARK: - Properties
    var authManager: AuthManager?
    var selectedTransactions: [Transaction] = []
    var category: String?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = category
        
        transactionTableView.delegate = self
        transactionTableView.dataSource = self
    }
}

// MARK: - UITableViewDelegate
extension SelectedTransactionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
}

// MARK: - UITableViewDataSource
extension SelectedTransactionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
        
        guard let currency = authManager?.currentUser?.currency else {
            fatalError("User data is nil")
        }
        
        cell.amountLabel.text = "\(selectedTransactions[indexPath.row].amount.round(to: 2))\(currency.symbolNative)"
        cell.dateLabel.text = selectedTransactions[indexPath.row].date
        
        return cell
    }
}
