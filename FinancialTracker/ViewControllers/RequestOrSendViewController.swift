//
//  Request+SendViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 14.02.22.
//

import UIKit

protocol RequestOrSendViewControllerDelegate: AnyObject {
    func requestOrSendVIewControllerShowTabBar(sender: RequestOrSendViewController)
}

class RequestOrSendViewController: UIViewController {
    @IBOutlet var actionTypeLabel: UILabel!
    @IBOutlet var recipientTextField: UITextField!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var actionTypeButton: UIButton!
    @IBOutlet var closeWindowButton: UIImageView!
    @IBOutlet var popUpView: UIView!
    
    var transferType: TransferType?
    var authManager: AuthManager?
    weak var delegate: RequestOrSendViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: true)
        
        popUpView.layer.cornerRadius = 10
        actionTypeLabel.text = transferType?.rawValue
        actionTypeButton.setTitle(transferType?.rawValue, for: .normal)
        amountTextField.placeholder = "Amount"
        recipientTextField.placeholder = "To Who (email)"
        let close = UITapGestureRecognizer(target: self, action: #selector(closeWindowButtonTapped))
        closeWindowButton.addGestureRecognizer(close)
        closeWindowButton.isUserInteractionEnabled = true
    }
    
    @objc func closeWindowButtonTapped() {
        self.delegate?.requestOrSendVIewControllerShowTabBar(sender: self)
        self.dismiss(animated: true)
    }
    
    @IBAction func requestOrSendButtonTapped(_ sender: Any) {
        actionTypeButton.isEnabled = false
        
        guard let email = recipientTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Email", message: "Please fill in the email"), animated: true)
            actionTypeButton.isEnabled = true
            return
        }
        
        guard let amount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !amount.isEmpty else {
            self.present(UIAlertController.create(title: "Missing Amount", message: "Please fill in the amount."), animated: true)
            actionTypeButton.isEnabled = true
            return
        }
        
        guard let amountNumber = Double(amount) else {
            self.present(UIAlertController.create(title: "Invalid Format", message: "Please fill in a number"), animated: true)
            actionTypeButton.isEnabled = true
            return
        }
        
        guard let transferType = transferType else {
            return
        }
        
        authManager?.transferMoney(email: email, amount: amountNumber, transferType: transferType, completionHandler: { firebaseError, user in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .nonExistingUser:
                    let alert = UIAlertController.create(title: "Invalid", message: "The user doesn't exist.")
                    self.present(alert, animated: true)
                    self.actionTypeButton.isEnabled = true
                default:
                    assertionFailure(firebaseError.localizedDescription)
                    self.actionTypeButton.isEnabled = true
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
                let newAmount = ((amountNumber / senderRate) * receiverRate).round(to: 2)
                
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
                            let alert = UIAlertController.create(title: "Error", message: error.localizedDescription)
                            self.present(alert, animated: true)
                        } else {
                            DispatchQueue.main.async {
                                self.actionTypeButton.isEnabled = true
                                self.closeWindowButtonTapped()
                            }
                        }
                    }
                }
            }
        })
    }
}
