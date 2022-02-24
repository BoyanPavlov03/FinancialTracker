//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

enum FinanceTips: Double {
    case lowBalance = 100.0
    case goodBalance = 1000.0
    case needToInvest = 3000.0
    case start = 0.0
    
    var description: String {
        switch self {
        case .lowBalance:
            return "Be careful with your finances. Try to spend less on things you don't need!"
        case .goodBalance:
            return "You are doing great! Keep doing so!"
        case .needToInvest:
            return "You have a lot of money stored. You can invest some of them in crypto or shares."
        case .start:
            return "We are delighted to have you on board. In here you can keep track of your finances. Be careful how you spend your money."
        }
    }
}

class TabBarController: UITabBarController {
    private var authManager: AuthManager?
    var accountCreated = false
    
    func setAuthManager(_ authManager: AuthManager, accountCreated: Bool) {
        self.authManager = authManager
        self.accountCreated = accountCreated
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting startup controller to Home
        selectedIndex = 1
        setupChildViewControllers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if accountCreated {
            present(UIAlertController.create(title: "Welcome", message: FinanceTips.start.description), animated: true)
            accountCreated = false
        }
        
        authManager?.firestoreDidChangeData { authError, user in
            if let authError = authError {
                switch authError {
                case .database(let error):
                    if let databaseError = error {
                        switch databaseError {
                        case .database(let error):
                            guard let error = error else { return }
                            self.present(UIAlertController.create(title: "Database Error", message: error.localizedDescription), animated: true)
                        case .access(let error):
                            guard let error = error else { return }
                            self.present(UIAlertController.create(title: "Access Error", message: error), animated: true)
                        case .unknown:
                            let alert = UIAlertController.create(title: "Unknown Error", message: databaseError.localizedDescription)
                            self.present(alert, animated: true)
                        default:
                            assertionFailure("This databaseError should not appear: \(databaseError.localizedDescription)")
                            return
                        }
                    }
                default:
                    assertionFailure("This authError should not appear: \(authError.localizedDescription)")
                    return
                }
            } else {
                guard let user = user, let balance = user.balance else {
                    return
                }

                guard user.premium else {
                    return
                }
                
                if user.expenses.isEmpty, user.incomes.isEmpty {
                    return
                }
                    
                self.balanceTips(balance: balance)
            }
        }
    }
    
    private func balanceTips(balance: Double) {
        if balance < FinanceTips.lowBalance.rawValue {
            self.present(UIAlertController.create(title: "Low Balance", message: FinanceTips.lowBalance.description), animated: true)
        } else if balance > FinanceTips.goodBalance.rawValue {
            self.present(UIAlertController.create(title: "Good Balance", message: FinanceTips.goodBalance.description), animated: true)
        } else if balance > FinanceTips.needToInvest.rawValue {
            self.present(UIAlertController.create(title: "Need Invest", message: FinanceTips.needToInvest.description), animated: true)
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
                    homeVC.authManager = authManager
                case let profileVC as ProfileViewController:
                    profileVC.authManager = authManager
                case let currencyVC as CurrencyTableViewController:
                    currencyVC.authManager = authManager
                case let remindersVC as RemindersTableViewController:
                    remindersVC.authManager = authManager
                default:
                    assertionFailure("This should not be here: \(String(describing: navigationController.topViewController)).")
                    return
                }
            }
        }
    }
}
