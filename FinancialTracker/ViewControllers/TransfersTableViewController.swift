//
//  TransfersTableViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 16.02.22.
//

import UIKit

class TransfersTableViewController: UIViewController {
    @IBOutlet var transfersHistoryTableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    var authManager: AuthManager?
    private var transfers: [TransferType: [Transfer]] = [:] {
        didSet {
            transfersHistoryTableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    private var noTransfers: Bool {
        for value in transfers.values {
            guard value.isEmpty else {
                return false
            }
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTransfersData()
        title = "Transfers"
        transfersHistoryTableView.dataSource = self
        transfersHistoryTableView.delegate = self
        transfersHistoryTableView.allowsSelection = false
        
        refreshControl.addTarget(self, action: #selector(setTransfersData), for: .valueChanged)
        transfersHistoryTableView.addSubview(refreshControl)
    }
    
    @objc private func setTransfersData() {
        authManager?.firestoreDidChangeUserTransfersData(completionHandler: { authError, userTransfers in
            guard let userTransfers = userTransfers else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
            
            var transfers: [TransferType: [Transfer]] = [:]
            
            for transfer in userTransfers {
                let transferType = transfer.transferType
                if transfers[transferType] == nil {
                    transfers[transferType] = []
                }
                transfers[transferType]?.append(transfer)
            }
            
            self.transfers = transfers
        })
    }
    
    @IBAction func sendOrRequestButtonTapped(_ sender: Any) {
        guard let usersVC = ViewControllerFactory.shared.viewController(for: .users) as? UsersTableViewController else {
            assertionFailure("Couldn't cast to UsersTableViewController.")
            return
        }
        usersVC.authManager = authManager
        self.navigationController?.pushViewController(usersVC, animated: true)
    }
}

extension TransfersTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if noTransfers {
            let size = transfersHistoryTableView.bounds.size
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            noDataLabel.text = "No Transfers Available"
            noDataLabel.textColor = UIColor(red: 22.0/255.0, green: 106.0/255.0, blue: 176.0/255.0, alpha: 1.0)
            noDataLabel.textAlignment = NSTextAlignment.center
            transfersHistoryTableView.backgroundView = noDataLabel
        } else {
            transfersHistoryTableView.backgroundView = nil
        }
        return transfers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transfers[section].value.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return transfers[section].key.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.dataSource?.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return 0
        } else {
            return 25.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let currentUser = authManager?.currentUser,
              let currency = currentUser.currency else {
                  fatalError("User data is nil")
        }
        
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransferTableViewCell", for: indexPath) as! TransferTableViewCell
        
        let value = transfers[indexPath.section].value[indexPath.row]
        cell.transferDate.text = value.date
        cell.transferStateButton.isEnabled = true
        switch value.transferType {
        case .send:
            cell.transferTitleLabel.text = "You want to send \(value.amount)\(currency.symbolNative)"
            switch value.transferState {
            case .pending:
                cell.transferStateButton.setTitle("Pending", for: .disabled)
            case .completed:
                cell.transferStateButton.setTitle("Sent", for: .disabled)
            }
            cell.transferStateButton.isEnabled = false
        case .requestToMe:
            let amountInMyCurrency = ((value.amount / value.senderCurrencyRate) * currency.rate).round(to: 2)
            cell.transferTitleLabel.text = "\(value.senderName) wants to send you \(amountInMyCurrency)\(currency.symbolNative)"
            switch value.transferState {
            case .pending:
                cell.transferStateButton.setTitle("Send", for: .normal)
            case .completed:
                cell.transferStateButton.setTitle("Sent", for: .disabled)
                cell.transferStateButton.isEnabled = false
            }
        case .requestFromMe:
            cell.transferTitleLabel.text = "You want \(value.amount)\(currency.symbolNative) from \(value.senderName)"
            switch value.transferState {
            case .pending:
                cell.transferStateButton.setTitle("Pending", for: .disabled)
            case .completed:
                cell.transferStateButton.setTitle("Sent", for: .disabled)
            }
            cell.transferStateButton.isEnabled = false
        case .receive:
            let amountInMyCurrency = ((value.amount / value.senderCurrencyRate) * currency.rate).round(to: 2)
            cell.transferTitleLabel.text = "You received \(amountInMyCurrency)\(currency.symbolNative) from \(value.senderName)"
            switch value.transferState {
            case .pending:
                cell.transferStateButton.setTitle("Accept", for: .normal)
            case .completed:
                cell.transferStateButton.setTitle("Received", for: .disabled)
                cell.transferStateButton.isEnabled = false
            }
        }
        cell.delegate = self
        
        return cell
    }
}

extension TransfersTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95.0
    }
}

extension TransfersTableViewController: TransferTableViewCellDelegate {
    func didTapTransferStateButton(sender: TransferTableViewCell) {
        if let indexPath = transfersHistoryTableView.indexPath(for: sender) {
            let transfer = transfers[indexPath.section].value[indexPath.row]
            authManager?.completeTransfer(transfer: transfer, completionHandler: { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."
                    
                    self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
            })
        }
    }
}
