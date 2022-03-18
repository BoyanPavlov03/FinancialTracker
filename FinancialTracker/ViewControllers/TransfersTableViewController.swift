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
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransferTableViewCell", for: indexPath) as! TransferTableViewCell
        
        let value = transfers[indexPath.section].value[indexPath.row]
        cell.transferTitleLabel.text = value.description
        cell.transferDate.text = value.date
        switch value.transferType {
        case .send:
            if case .pending = value.transferState {
                cell.transferStateButton.setTitle("Pending", for: .disabled)
            } else {
                cell.transferStateButton.setTitle("Sent", for: .disabled)
            }
            cell.transferStateButton.isEnabled = false
        case .requestToMe:
            if case .pending = value.transferState {
                cell.transferStateButton.setTitle("Send", for: .normal)
            } else {
                cell.transferStateButton.setTitle("Sent", for: .disabled)
                cell.transferStateButton.isEnabled = false
            }
        case .requestFromMe:
            if case .pending = value.transferState {
                cell.transferStateButton.setTitle("Pending", for: .disabled)
            } else {
                cell.transferStateButton.setTitle("Sent", for: .disabled)
            }
            cell.transferStateButton.isEnabled = false
        case .receive:
            if case .pending = value.transferState {
                cell.transferStateButton.setTitle("Accept", for: .normal)
            } else {
                cell.transferStateButton.setTitle("Received", for: .disabled)
                cell.transferStateButton.isEnabled = false
            }
        }
        cell.delegate = self
        cell.section = indexPath.section
        cell.row = indexPath.row
        
        return cell
    }
}

extension TransfersTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95.0
    }
}

extension TransfersTableViewController: TransferTableViewCellDelegate {
    func didTapTransferStateButton(with title: String, section: Int, row: Int) {
        let transfer = transfers[section].value[row]
        switch title {
        case "Send":
            authManager?.sendRequestedTransferFromUserByUID(transfer.fromUser, transfer: transfer, completionHandler: { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."

                    self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
                
                self.authManager?.completeTransfer(transfer: transfer, completionHandler: { authError, success in
                    guard success else {
                        let alertTitle = authError?.title ?? "Unknown Error"
                        let alertMessage = authError?.message ?? "This error should not appear."

                        self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                        return
                    }
                })
            })
        case "Accept":
            authManager?.acceptTransferFromUserByUID(transfer.toUser, transfer: transfer, completionHandler: { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."

                    self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
                
                self.authManager?.completeTransfer(transfer: transfer, completionHandler: { authError, success in
                    guard success else {
                        let alertTitle = authError?.title ?? "Unknown Error"
                        let alertMessage = authError?.message ?? "This error should not appear."

                        self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                        return
                    }
                })
            })
        default:
            assertionFailure("Should not appear.")
            return
        }
    }
}
