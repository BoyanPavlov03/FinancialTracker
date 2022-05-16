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

protocol PremiumViewControllerDelegate: AnyObject {
    func didPurchasePremium(sender: PremiumViewController)
}

class PremiumViewController: UIViewController {
    // MARK: - Outlet properties
    @IBOutlet var upgradeButton: UIButton!
    @IBOutlet var proButton: UIButton!
    
    // MARK: - Properties
    var authManager: AuthManager?
    weak var delegate: PremiumViewControllerDelegate?
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Premium"
        
        SKPaymentQueue.default().add(self)
        upgradeButton.layer.cornerRadius = 15
        proButton.layer.cornerRadius = 15
        guard let currency = authManager?.currentUser?.currency else {
            fatalError("User data is nil")
        }
        
        let amount = (currency.rate * 8.42).round(to: currency.symbolsAfterComma)
        upgradeButton.setTitle("Upgrade Premium \(Locale.getLocalizedAmount(amount))\(currency.symbolNative)", for: .normal)
    }
    
    // MARK: - IBAction methods
    @IBAction func upgradeButtonTapped(_ sender: Any) {
        if SKPaymentQueue.canMakePayments() {
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = Product.premium.rawValue
            
            SKPaymentQueue.default().add(paymentRequest)
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension PremiumViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                authManager?.buyPremium { authError, success in
                    guard success else {
                        let alertTitle = authError?.title ?? "Unknown Error"
                        let alertMessage = authError?.message ?? "This error should not appear."
                        
                        self.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                        return
                    }
                    self.delegate?.didPurchasePremium(sender: self)
                    self.navigationController?.popViewController(animated: true)
                }
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
