//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

private enum FinanceTips: Double {
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
    // MARK: - Private properties
    private var authManager: AuthManager?
    private var accountCreated = false
    
    // MARK: - Lifecycle methods
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
            guard let user = user else {
                let alertTitle = authError?.title ?? "Unknown Error"
                let alertMessage = authError?.message ?? "This error should not appear."
                
                self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                return
            }
            
            guard let balance = user.balance else {
                fatalError("User data is nil.")
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
    
    // MARK: - Own methods
    func setAuthManager(_ authManager: AuthManager, accountCreated: Bool) {
        self.authManager = authManager
        self.accountCreated = accountCreated
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
                case let transfersVC as TransfersTableViewController:
                    transfersVC.authManager = authManager
                default:
                    assertionFailure("This should not be here: \(String(describing: navigationController.topViewController)).")
                    return
                }
            }
        }
    }
}
