//
//  UsersViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 22.02.22.
//

import UIKit

class UsersTableViewController: UITableViewController {
    var usersEmails: [String]?
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authManager?.getAllUsers(completionHandler: { firebaseError, emails in
            if let firebaseError = firebaseError {
                assertionFailure(firebaseError.localizedDescription)
                return
            }
            self.usersEmails = emails
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersEmails?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath)
        
        cell.textLabel?.text = usersEmails?[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let email = usersEmails?[indexPath.row] else {
            assertionFailure("Non exisiting email.")
            return
        }
        
        let alertVC = UIAlertController(title: "Enter amount", message: email, preferredStyle: .alert)
        
        alertVC.addTextField { textField in
            textField.placeholder = "Amount"
        }

        alertVC.addAction(UIAlertAction(title: "Request", style: .default, handler: { _ in
            guard let amount = alertVC.textFields?[0].text else {
                assertionFailure("Empty textField.")
                return
            }

            guard let amountValue = Double(amount) else {
                assertionFailure("Enter a number.")
                return
            }

            self.requestOrSend(email: email, amount: amountValue, transferType: TransferType.request)
        }))

        alertVC.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
            guard let amount = alertVC.textFields?[0].text else {
                assertionFailure("Empty textField.")
                return
            }

            guard let amountValue = Double(amount) else {
                assertionFailure("Enter a number.")
                return
            }

            self.requestOrSend(email: email, amount: amountValue, transferType: TransferType.send)
        }))
        
        self.present(alertVC, animated: true) {
            alertVC.view.superview?.isUserInteractionEnabled = true
            alertVC.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped)))
        }
    }
    
    @objc func backgroundTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func requestOrSend(email: String, amount: Double, transferType: TransferType) {
        authManager?.transferMoney(email: email, amount: amount, transferType: transferType, completionHandler: { firebaseError, user in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .nonExistingUser:
                    let alert = UIAlertController.create(title: "Invalid", message: "The user doesn't exist.")
                    self.present(alert, animated: true)
                default:
                    assertionFailure(firebaseError.localizedDescription)
                    return
                }
            } else {
                guard let senderRate = self.authManager?.currentUser?.currency?.rate else {
                    return
                }
                
                guard let firstName = self.authManager?.currentUser?.firstName, let lastName = self.authManager?.currentUser?.lastName else {
                    return
                }
                
                guard let receiverRate = user?.currency?.rate, let symbol = user?.currency?.symbolNative, let fcmToken = user?.FCMToken else {
                    return
                }
                let newAmount = ((amount / senderRate) * receiverRate).round(to: 2)
                
                if user != nil {
                    var title: String
                    var body: String
                    
                    switch transferType {
                    case .send:
                        title = "You have got money"
                        body = "\(firstName) \(lastName) send you \(newAmount)\(symbol)"
                    case .request:
                        title = "Money requested"
                        body = "\(firstName) \(lastName) wants \(newAmount)\(symbol) from you"
                    }
                    
                    // swiftlint:disable:next line_length
                    PushNotificatonSender.sendPushNotificationForMoneyTransfer(to: fcmToken, title: title, body: body, amount: newAmount, transferType: transferType) { error in
                        if let error = error {
                            assertionFailure(error.localizedDescription)
                            return
                        }
                    }
                }
            }
        })
    }
}
