//
//  Request+SendViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 14.02.22.
//

import UIKit

protocol RequestOrSendViewControllerDelegate: AnyObject {
    func showTabBar(sender: RequestOrSendViewController)
}

class RequestOrSendViewController: UIViewController {
    @IBOutlet var actionTypeLabel: UILabel!
    @IBOutlet var recipientTextField: UITextField!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var actionTypeButton: UIButton!
    @IBOutlet var closeButton: UIImageView!
    @IBOutlet var boxView: UIView!
    
    var type: ReminderType?
    var authManager: AuthManager?
    weak var delegate: RequestOrSendViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: true)
        
        boxView.layer.cornerRadius = 10
        actionTypeLabel.text = type?.rawValue
        actionTypeButton.setTitle(type?.rawValue, for: .normal)
        amountTextField.placeholder = "Amount"
        recipientTextField.placeholder = "To Who (email)"
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeWindow))
        closeButton.addGestureRecognizer(tapGestureRecognizer)
        closeButton.isUserInteractionEnabled = true
    }
    
    @objc func closeWindow() {
        self.delegate?.showTabBar(sender: self)
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
        
        guard let type = type else {
            return
        }
        
        authManager?.sendOrRequestMoney(email: email, amount: amountNumber, reminderType: type, completionHandler: { firebaseError, user in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .nonExisting:
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
                
                guard let receiverRate = user?.currency?.rate, let symbol = user?.currency?.symbolNative else {
                    return
                }
                let newAmount = ((amountNumber / senderRate) * receiverRate).round(to: 2)
                
                if let user = user {
                    var title = ""
                    var body = ""
                    
                    switch type {
                    case .send:
                        title = "You have got money"
                        body = "\(user.firstName) \(user.lastName) send you \(newAmount)\(symbol)"
                    case .request:
                        title = "Money requested"
                        body = "\(user.firstName) \(user.lastName) wants \(newAmount)\(symbol) from you"
                    }
                    
                    PushNotificatonSender.sendPushNotification(to: user.fcmToken, title: title, body: body, type: type)
                    self.actionTypeButton.isEnabled = true
                    self.closeWindow()
                }
            }
        })
    }
}
