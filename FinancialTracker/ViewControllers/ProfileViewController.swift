//
//  ProfileViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 19.01.22.
//

import UIKit
import MessageUI

struct Constants {
    static let shareText = "Wanna keep track of your finance life. Click the link to install this new amazing app on the App Store:"
    static let shareLink = "www.google.com"
}

class ProfileViewController: UIViewController {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var expensesCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Profile"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        self.tabBarItem.image = UIImage(systemName: "person")
        
        guard let user = FirebaseHandler.shared.currentUser else {
            assertionFailure("User data is nil")
            return
        }
        
        nameLabel.text = "\(user.firstName) \(user.lastName)"
        emailLabel.text = user.email
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let user = FirebaseHandler.shared.currentUser, let balance = user.balance else {
            assertionFailure("User data is nil")
            return
        }
        
        balanceLabel.text = "Balance\n \(balance)"
        expensesCountLabel.text = "Expenses\n \(user.expenses.count)"
    }
    
    @objc func signOut() {
        FirebaseHandler.shared.signOut { firebaseError, _ in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .signOut(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Sign Out Error", message: error.localizedDescription), animated: true)
                case .database, .unknown, .access, .auth:
                    assertionFailure("This error should not appear: \(firebaseError.localizedDescription)")
                    // swiftlint:disable:next unneeded_break_in_switch
                    break
                }
            }
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        let activityVC = UIActivityViewController(activityItems: [Constants.shareText, Constants.shareLink], applicationActivities: nil)
        
        activityVC.popoverPresentationController?.sourceView = self.view
        present(activityVC, animated: true)
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Support", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Support.addExpense.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Support.refundMoney.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        
        present(alertController, animated: true)
    }
    
    private func setComposerMessage(action: UIAlertAction) {
        guard MFMailComposeViewController.canSendMail() else {
            assertionFailure("Mail services are not available")
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([Support.Constants.email])
        
        composer.setSubject(action.title ?? Support.other.rawValue)
        present(composer, animated: true)
    }
}

extension ProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard error == nil else {
            controller.dismiss(animated: true)
            return
        }
        
        controller.dismiss(animated: true)
    }
}
