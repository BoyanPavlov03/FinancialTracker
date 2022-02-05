//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

class TabBarController: UITabBarController {
    var authManager: AuthManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChildViewControllers()
        
        guard let currentUser = authManager?.databaseManager.currentUser else {
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
                switch navigationController.topViewController {
                case let homeVC as HomeViewController:
                    homeVC.databaseManager = authManager?.databaseManager
                case let profileVC as ProfileViewController:
                    profileVC.databaseManager = authManager?.databaseManager
                case let currencyVC as CurrencyTableViewController:
                    currencyVC.databaseManager = authManager?.databaseManager
                case let premiumVC as PremiumViewController:
                    premiumVC.databaseManager = authManager?.databaseManager
                default:
                    break
                }
            }
        }
    }
}
