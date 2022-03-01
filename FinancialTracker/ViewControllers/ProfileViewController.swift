//
//  ProfileViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 19.01.22.
//

import UIKit
import MessageUI

enum ProfileViewControllerSettings: String, CaseIterable {
    case changeCurrency = "Change Currency"
    case support = "Support"
    case premium = "Upgrade to Premium"
}

class ProfileViewController: UIViewController {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userTypeLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var settingsTableView: UITableView!
    
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        navigationItem.setHidesBackButton(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        tabBarItem.image = UIImage(systemName: "person")
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        
        guard let user = authManager?.currentUser, let balance = user.balance, let currency = user.currency else {
            assertionFailure("User data is nil")
            return
        }
        
        nameLabel.text = "\(user.firstName) \(user.lastName)"
        emailLabel.text = user.email
        balanceLabel.text = "Balance: \(balance)\(currency.symbolNative)"
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
        
        balanceLabel.text = "Balance: \(balance.round(to: 2))\(currency.symbolNative)"
        userTypeLabel.text = "User Type: \(user.premium ? "Premium" : "Normal")"
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        let activityVC = UIActivityViewController(activityItems: [Constants.Share.shareText, Constants.Share.shareLink], applicationActivities: nil)
        
        activityVC.popoverPresentationController?.sourceView = self.view
        present(activityVC, animated: true)
    }
    
    private func helpCellTapped() {
        let alertController = UIAlertController(title: "Support", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Constants.Support.addExpense, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Constants.Support.refundMoney, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alertController, animated: true)
    }

    private func upgradeCellTapped() {
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
        composer.setToRecipients([Constants.Support.email])
        composer.setSubject(action.title ?? Constants.Support.other)
        present(composer, animated: true)
    }
    
    private func changeCurrencyCellTapped() {
        guard let currencyVC = ViewControllerFactory.shared.viewController(for: .currency) as? CurrencyTableViewController else {
            assertionFailure("Couldn't cast to CurrencyTableViewController")
            return
        }
        currencyVC.authManager = authManager
        
        navigationController?.pushViewController(currencyVC, animated: true)
    }
    
    @objc private func signOut() {
        let alertController = UIAlertController(title: "Sign Out", message: "You are about to sign out. Are you sure?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            self.authManager?.signOut { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."
                    
                    self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
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

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            changeCurrencyCellTapped()
        case 1:
            helpCellTapped()
        case 2:
            upgradeCellTapped()
        default:
            assertionFailure("This should not happen.")
            return
        }
    }
}

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Settings"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let premium = authManager?.currentUser?.premium else {
            assertionFailure("User data is nil")
            return 0
        }
        
        let count = ProfileViewControllerSettings.allCases.count
        return premium ? count - 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath)
        
        cell.textLabel?.text = ProfileViewControllerSettings.allCases[indexPath.row].rawValue
        if ProfileViewControllerSettings.allCases[indexPath.row] == .changeCurrency {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
}
