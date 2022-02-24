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
                    if let authError = authError {
                        switch authError {
                        case .database(let error):
                            if let databaseError = error {
                                switch databaseError {
                                case .database(let error):
                                    guard let error = error else { return }
                                    let alert = UIAlertController.create(title: "Database Error", message: error.localizedDescription)
                                    self.present(alert, animated: true)
                                case .access(let error):
                                    guard let error = error else { return }
                                    let alert = UIAlertController.create(title: "Access Error", message: error)
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
