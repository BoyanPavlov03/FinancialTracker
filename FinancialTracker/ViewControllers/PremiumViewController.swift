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

        title = "Premium"
        
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
                authManager?.buyPremium { authError, _ in
                    if let alert = UIAlertController.create(basedOnAuthError: authError) {
                        self.present(alert, animated: true)
                        return
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
