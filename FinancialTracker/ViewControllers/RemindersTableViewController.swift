//
//  RemindersTableViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 16.02.22.
//

import UIKit

class RemindersTableViewController: UIViewController {
    @IBOutlet var transfersHistoryTableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    var authManager: AuthManager?
    private var transfers: [TransferType: [Reminder]] = [:] {
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
        var transfers: [TransferType: [Reminder]] = [:]
        guard let reminders = authManager?.currentUser?.reminders else {
            return
        }
        
        for reminder in reminders {
            let transferType = reminder.transferType
            if transfers[transferType] == nil {
                transfers[transferType] = []
            }
            transfers[transferType]?.append(reminder)
        }
        
        self.transfers = transfers
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

extension RemindersTableViewController: UITableViewDataSource {
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
        
        cell.transferTitleLabel.text = transfers[indexPath.section].value[indexPath.row].description
        cell.transferDate.text = transfers[indexPath.section].value[indexPath.row].date
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // May change in the future
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reminder = transfers[indexPath.section].value[indexPath.row]
            authManager?.deleteReminderFromCurrentUser(reminder: reminder, completionHandler: { authError, _ in
                if let authError = authError {
                    switch authError {
                    case .database(let error):
                        if let databaseError = error {
                            switch databaseError {
                            case .database(let error):
                                guard let error = error else { return }
                                self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
                            case .access(let error):
                                guard let error = error else { return }
                                self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
                            default:
                                assertionFailure("This databaseError should not appear: \(databaseError.localizedDescription)")
                                return
                            }
                        }
                    default:
                        assertionFailure("This authError should not appear: \(authError.localizedDescription)")
                        return
                    }
                } else {
                    let transfers = self.transfers[indexPath.section].value
                    let key = self.transfers[indexPath.section].key
                    if let index = transfers.firstIndex(of: reminder) {
                        self.transfers[key]?.remove(at: index)
                    }
                }
            })
        }
    }
}

extension RemindersTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}
