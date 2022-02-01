//
//  PremiumViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 26.01.22.
//

import UIKit
import StoreKit

enum Product: String {
    case premium = "org.elsys.premium"
}

class PremiumViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Premium"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        self.tabBarItem.image = UIImage(systemName: "star")
        
        SKPaymentQueue.default().add(self)
    }
    
    @IBAction func upgradeButtonTapped(_ sender: Any) {
        if SKPaymentQueue.canMakePayments() {
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = Product.premium.rawValue
            
            SKPaymentQueue.default().add(paymentRequest)
        }
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

}

extension PremiumViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                FirebaseHandler.shared.buyPremium { firebaseError, _ in
                    if let firebaseError = firebaseError {
                        assertionFailure(firebaseError.localizedDescription)
                        return
                    }
                }
                
                guard var viewControllers = self.tabBarController?.viewControllers else { return }
                // Remove the premium tab as the user now owns it
                viewControllers.remove(at: 3)
                self.tabBarController?.viewControllers = viewControllers
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
