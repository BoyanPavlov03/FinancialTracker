//
//  UsersViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 22.02.22.
//

import UIKit

class UsersTableViewController: UITableViewController {
    var usersEmails: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Users"
        authManager?.getAllUsers(completionHandler: { authError, usersEmails in
            if let alert = UIAlertController.create(basedOn: authError) {
                self.present(alert, animated: true)
                return
            } else {
                guard let usersEmails = usersEmails else {
                    assertionFailure("Emails are nil.")
                    return
                }
                
                self.usersEmails = usersEmails
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersEmails.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath)
        
        cell.textLabel?.text = usersEmails[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: "Enter amount", message: usersEmails[indexPath.row], preferredStyle: .alert)
        
        alertVC.addTextField { textField in
            textField.placeholder = "Amount"
        }
        
        let requestAlertAction = UIAlertAction(title: "Request", style: .default, handler: { _ in
            guard let amount = alertVC.textFields?[0].text else {
                assertionFailure("Empty textField.")
                return
            }
            
            guard let amountValue = Double(amount) else {
                assertionFailure("Enter a number.")
                return
            }
            
            self.requestOrSend(email: self.usersEmails[indexPath.row], amount: amountValue, transferType: TransferType.request)
        })
        alertVC.addAction(requestAlertAction)
        
        let sendAlertAction = UIAlertAction(title: "Send", style: .default, handler: { _ in
            guard let amount = alertVC.textFields?[0].text else {
                assertionFailure("Empty textField.")
                return
            }
            
            guard let amountValue = Double(amount) else {
                assertionFailure("Enter a number.")
                return
            }
            
            self.requestOrSend(email: self.usersEmails[indexPath.row], amount: amountValue, transferType: TransferType.send)
        })
        alertVC.addAction(sendAlertAction)
        
        self.present(alertVC, animated: true) {
            alertVC.view.superview?.isUserInteractionEnabled = true
            alertVC.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped)))
        }
    }
    
    @objc private func backgroundTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func requestOrSend(email: String, amount: Double, transferType: TransferType) {
        authManager?.transferMoney(email: email, amount: amount, transferType: transferType, completionHandler: { authError, user in
            if let alert = UIAlertController.create(basedOn: authError) {
                self.present(alert, animated: true)
                return
            } else {
                guard let currentUser = self.authManager?.currentUser, let senderRate = currentUser.currency?.rate else {
                    return
                }
                
                guard let user = user, let receiverCurrency = user.currency, let fcmToken = user.FCMToken else {
                    return
                }
                let newAmount = ((amount / senderRate) * receiverCurrency.rate).round(to: 2)
                
                var title: String
                var body: String
                
                switch transferType {
                case .send:
                    title = "You have got money"
                    body = "\(currentUser.firstName) \(currentUser.lastName) send you \(newAmount)\(receiverCurrency.symbolNative)"
                case .request:
                    title = "Money requested"
                    body = "\(currentUser.firstName) \(currentUser.lastName) wants \(newAmount)\(receiverCurrency.symbolNative) from you"
                }
                
                // swiftlint:disable:next line_length
                PushNotificatonSender.sendPushNotificationForMoneyTransfer(to: fcmToken, title: title, body: body, amount: newAmount, transferType: transferType) { error in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                        return
                    }
                }
            }
        })
    }
}
