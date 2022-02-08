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

    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Premium"
        self.navigationItem.setHidesBackButton(true, animated: true)
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
}

extension PremiumViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                authManager?.buyPremium { firebaseError, _ in
                    if let firebaseError = firebaseError {
                        assertionFailure(firebaseError.localizedDescription)
                        return
                    }
                }
                
                // Remove the premium tab as the user now owns it
                self.tabBarController?.viewControllers?.remove(at: 3)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
