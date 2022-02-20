//
//  ProfileViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 19.01.22.
//

import UIKit
import MessageUI

struct ShareConstants {
    static let shareText = "Wanna keep track of your finance life. Click the link to install this new amazing app on the App Store:"
    static let shareLink = "https://app.bitrise.io/artifact/113971239/p/a364f20e4db777fa7e692386989d3053"
}

class ProfileViewController: UIViewController {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userTypeLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var premiumButton: UIButton!
    
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Profile"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.tabBarItem.image = UIImage(systemName: "person")
        
        guard let user = authManager?.currentUser, let balance = user.balance, let currency = user.currency else {
            assertionFailure("User data is nil")
            return
        }
        
        if user.premium {
            premiumButton.isHidden = true
        }
        
        nameLabel.text = "\(user.firstName) \(user.lastName)"
        emailLabel.text = user.email
        balanceLabel.text = "Balance\n \(balance)\(currency.symbolNative)"
        userTypeLabel.text = "User Type: \(user.premium ? "Premium" : "Normal")"
        
        authManager?.addDelegate(self)
    }
    
    private func updateBalanceAndExpenses() {
        guard let user = authManager?.currentUser, let balance = user.balance, let currency = user.currency else {
            assertionFailure("User data is nil")
            return
        }
        if balance < 0 {
            balanceLabel.textColor = .red
        } else if balance > 3000 {
            balanceLabel.textColor = .green
        }
        
        balanceLabel.text = "Balance\n \(balance.round(to: 2))\(currency.symbolNative)"
        userTypeLabel.text = "User Type: \(user.premium ? "Premium" : "Normal")"
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        let activityVC = UIActivityViewController(activityItems: [ShareConstants.shareText, ShareConstants.shareLink], applicationActivities: nil)
        
        activityVC.popoverPresentationController?.sourceView = self.view
        present(activityVC, animated: true)
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Support", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Support.addExpense.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Support.refundMoney.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    @IBAction func upgradeButtonTapped(_ sender: Any) {
        guard let premiumVC = ViewControllerFactory.shared.viewController(for: .premium) as? PremiumViewController else {
            assertionFailure("Couldn't cast to PremiumViewController")
            return
        }
        
        premiumVC.authManager = authManager
        navigationController?.pushViewController(premiumVC, animated: true)
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

extension ProfileViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        updateBalanceAndExpenses()
    }
}
