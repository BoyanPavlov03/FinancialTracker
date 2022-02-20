//
//  RemindersTableViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 16.02.22.
//

import UIKit

class RemindersTableViewController: UITableViewController {

    var authManager: AuthManager?
    var transfers: [String: [Reminder]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTransfersData()
        self.title = "Transfers"
        
        self.tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc func refresh() {
        setTransfersData()
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    private func setTransfersData() {
        var transfers: [String: [Reminder]] = [:]
        guard let reminders = authManager?.currentUser?.reminders else {
            return
        }
        
        for reminder in reminders {
            let transferType = reminder.type.rawValue
            if transfers[transferType] == nil {
                transfers[transferType] = []
            }
            transfers[transferType]?.append(reminder)
        }
        
        self.transfers = transfers
    }
    
    private func isEmpty() -> Bool {
        for (_, value) in transfers {
            guard value.isEmpty else {
                return false
            }
        }
        return true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isEmpty() {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
            noDataLabel.text = "No Transfers Available"
            noDataLabel.textColor = UIColor(red: 22.0/255.0, green: 106.0/255.0, blue: 176.0/255.0, alpha: 1.0)
            noDataLabel.textAlignment = NSTextAlignment.center
            self.tableView.backgroundView = noDataLabel
        } else {
            self.tableView.backgroundView = nil
        }
        return transfers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transfers[section].value.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return transfers[section].key
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.dataSource?.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return 0
        } else {
            return 25.0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "Reminder", for: indexPath) as! TransferTableViewCell
        
        cell.transferTitleLabel.text = transfers[indexPath.section].value[indexPath.row].description
        cell.transferDate.text = transfers[indexPath.section].value[indexPath.row].date
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reminder = transfers[indexPath.section].value[indexPath.row]
            authManager?.deleteReminderFromCurrentUser(reminder, completionHandler: { firebaseError, _ in
                if let firebaseError = firebaseError {
                    let alert = UIAlertController.create(title: "Fail", message: "Couldn't delete reminder.\(firebaseError.localizedDescription)")
                    self.present(alert, animated: true)
                } else {
                    let transfers = self.transfers[indexPath.section].value
                    let key = self.transfers[indexPath.section].key
                    if let index = transfers.firstIndex(of: reminder) {
                        self.transfers[key]?.remove(at: index)
                    }
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.endUpdates()
                    tableView.reloadData()
                }
            })
        }
    }
    
}
