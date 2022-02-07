//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

class TabBarController: UITabBarController {
    private var authManager: AuthManager?
    private var databaseManager: DatabaseManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func setDatabaseManager(_ databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChildViewControllers()
        
        guard let currentUser = databaseManager?.currentUser else {
            assertionFailure("User data is nil")
            return
        }
        
        if currentUser.premium {
            // Remove the premium tab as the user owns it
            self.viewControllers?.remove(at: 3)
        }
    }
    
    private func setupChildViewControllers() {
        guard let viewControllers = viewControllers else {
            return
        }

        for viewController in viewControllers {
            if let navigationController = viewController as? UINavigationController {
                let signOutButton = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
                switch navigationController.topViewController {
                case let homeVC as HomeViewController:
                    homeVC.databaseManager = databaseManager
                    homeVC.navigationItem.rightBarButtonItem = signOutButton
                case let profileVC as ProfileViewController:
                    profileVC.databaseManager = databaseManager
                    profileVC.navigationItem.rightBarButtonItem = signOutButton
                case let currencyVC as CurrencyTableViewController:
                    currencyVC.databaseManager = databaseManager
                    currencyVC.navigationItem.rightBarButtonItem = signOutButton
                case let premiumVC as PremiumViewController:
                    premiumVC.databaseManager = databaseManager
                    premiumVC.navigationItem.rightBarButtonItem = signOutButton
                default:
                    break
                }
            }
        }
    }
    
    @objc func signOut() {
        authManager?.signOut { firebaseError, _ in
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
}
