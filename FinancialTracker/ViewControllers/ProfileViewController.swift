//
//  ProfileViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 19.01.22.
//

import UIKit
import MessageUI

private enum ProfileViewControllerSettings: String, CaseIterable {
    case changeCurrency = "Change Currency"
    case support = "Support"
    case premium = "Upgrade to Premium"
}

class ProfileViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userTypeLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var settingsTableView: UITableView!
    
    // MARK: - Properties
    var authManager: AuthManager?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        navigationItem.setHidesBackButton(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(shareButtonTapped))
        tabBarItem.image = UIImage(systemName: "person")
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        
        guard let currentUser = authManager?.currentUser,
              let balance = currentUser.balance,
              let currency = currentUser.currency else {
            fatalError("User data is nil")
        }
                
        nameLabel.text = "\(currentUser.firstName) \(currentUser.lastName)"
        emailLabel.text = currentUser.email
        balanceLabel.text = "Balance: \(Locale.getLocalizedAmount(balance))\(currency.symbolNative)"
        userTypeLabel.text = "User Type: \(currentUser.premium ? "Premium" : "Normal")"
        
        authManager?.addDelegate(self)
    }
    
    deinit {
        authManager?.removeDelegate(self)
    }
    
    // MARK: - Own methods
    private func updateBalanceAndExpenses() {
        guard let currentUser = authManager?.currentUser,
              let balance = currentUser.balance,
              let currency = currentUser.currency else {
            fatalError("User data is nil")
        }
        
        if balance < 0 {
            balanceLabel.textColor = .red
        } else if balance > 3000 {
            balanceLabel.textColor = .green
        }
        
        balanceLabel.text = "Balance: \(Locale.getLocalizedAmount(balance))\(currency.symbolNative)"
        userTypeLabel.text = "User Type: \(currentUser.premium ? "Premium" : "Normal")"
    }
    
    private func helpCellTapped(rect: CGRect) {
        let alertController = UIAlertController(title: "Support", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Constants.Support.addTransaction, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Constants.Support.refundTransfer, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Constants.Support.currencyNotChanging, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let bounds = settingsTableView.convert(rect, to: settingsTableView.superview)
            
        alertController.popoverPresentationController?.sourceRect = bounds
        alertController.popoverPresentationController?.sourceView = self.view
        present(alertController, animated: true)
    }

    private func upgradeCellTapped() {
        guard let premiumVC = ViewControllerFactory.shared.viewController(for: .premium) as? PremiumViewController else {
            assertionFailure("Couldn't cast to PremiumViewController")
            return
        }

        premiumVC.delegate = self
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
    
    // MARK: - IBAction methods
    @objc func shareButtonTapped() {
        let activityVC = UIActivityViewController(activityItems: [Constants.Share.shareText, Constants.Share.shareLink], applicationActivities: nil)
        
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(activityVC, animated: true)
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

// MARK: - MFMailComposeViewControllerDelegate
extension ProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            self.present(UIAlertController.create(title: "Error", message: error.localizedDescription), animated: true)
            return
        }

        controller.dismiss(animated: true)
    }
}

// MARK: - DatabaseManagerDelegate
extension ProfileViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        updateBalanceAndExpenses()
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            changeCurrencyCellTapped()
        case 1:
            let rect = tableView.rectForRow(at: indexPath)
            helpCellTapped(rect: rect)
        case 2:
            upgradeCellTapped()
        default:
            assertionFailure("This should not happen.")
            return
        }
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Settings"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil")
        }
        
        let count = ProfileViewControllerSettings.allCases.count
        return currentUser.premium ? count - 1 : count
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

extension ProfileViewController: PremiumViewControllerDelegate {
    func didPurchasePremium(sender: PremiumViewController) {
        settingsTableView.reloadData()
    }
}
