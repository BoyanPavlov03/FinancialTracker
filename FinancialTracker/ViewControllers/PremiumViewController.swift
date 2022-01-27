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
    }
    
    @IBAction func upgradeButtonTapped(_ sender: Any) {
        if SKPaymentQueue.canMakePayments() {
            let set: Set<String> = [Product.premium.rawValue]
            
            let productRequest = SKProductsRequest(productIdentifiers: set)
            productRequest.delegate = self
            productRequest.start()
        }
    }
    
    private func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
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

extension PremiumViewController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let product = response.products.first {
            self.purchase(product: product)
        }
    }
}

extension PremiumViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                FirebaseHandler.shared.boughtPremium { firebaseError, _ in
                    if let firebaseError = firebaseError {
                        assertionFailure(firebaseError.localizedDescription)
                        return
                    }
                }
                
                guard var viewControllers = self.tabBarController?.viewControllers else { return }
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