//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

struct FinanceTips {
    static let lowBalance = "Be careful with your finances. Try to spend less on things you don't need!"
    static let goodBalance = "You are doing great! Keep doing so!"
    static let needToInvest = "You have a lot of money stored. You can invest some of them in crypto or shares."
    static let start = "We are delighted to have you on board. In here you can keep track of your finances. Be careful how you spend your money."
}

class TabBarController: UITabBarController {
    private var authManager: AuthManager?
    private var didJustMadeAccount = false
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func justMadeAccount() {
        self.didJustMadeAccount = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChildViewControllers()
        
        guard let currentUser = authManager?.currentUser else {
            assertionFailure("User data is nil")
            return
        }
        
        if currentUser.premium {
            // Remove the premium tab as the user owns it
            self.viewControllers?.remove(at: 3)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didJustMadeAccount {
            self.present(UIAlertController.create(title: "Welcome", message: FinanceTips.start), animated: true)
            didJustMadeAccount = false
        }
        
        authManager?.firestoreDidChangeData { firebaseError, user in
            if let firebaseError = firebaseError {
                switch firebaseError {
                case .access(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
                case .database(let error):
                    guard let error = error else { return }
                    self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
                default:
                    self.present(UIAlertController.create(title: "Unknown Error", message: "Unknown"), animated: true)
                }
            } else {
                guard let user = user, let balance = user.balance else {
                    return
                }

                if user.expenses.isEmpty, user.incomes.isEmpty {
                    return
                }
                
                if balance < 100 {
                    self.present(UIAlertController.create(title: "Low Balance", message: FinanceTips.lowBalance), animated: true)
                } else if balance > 1000 {
                    self.present(UIAlertController.create(title: "Good Balance", message: FinanceTips.goodBalance), animated: true)
                } else if balance > 3000 {
                    self.present(UIAlertController.create(title: "Need Invest", message: FinanceTips.needToInvest), animated: true)
                }
            }
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
                    homeVC.authManager = authManager
                    homeVC.navigationItem.rightBarButtonItem = signOutButton
                case let profileVC as ProfileViewController:
                    profileVC.authManager = authManager
                    profileVC.navigationItem.rightBarButtonItem = signOutButton
                case let currencyVC as CurrencyTableViewController:
                    currencyVC.authManager = authManager
                    currencyVC.navigationItem.rightBarButtonItem = signOutButton
                case let premiumVC as PremiumViewController:
                    premiumVC.authManager = authManager
                    premiumVC.navigationItem.rightBarButtonItem = signOutButton
                default:
                    break
                }
            }
        }
    }
    
    @objc func signOut() {
        let alertController = UIAlertController(title: "Sign Out", message: "You are about to sign out. Are you sure?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            self.authManager?.signOut { firebaseError, _ in
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
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
}
