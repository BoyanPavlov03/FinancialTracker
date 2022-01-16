//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit
import Charts
import MessageUI

enum Support: String {
    case addExpense = "Problem adding an expense"
    case refundMoney = "Want a refund"
    case other = "Other"
    
    struct Constants {
        static let email = "support_financialTracker@gmail.com"
    }
}

class HomeViewController: UIViewController {
    @IBOutlet var expenseChart: PieChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Help", style: .plain, target: self, action: #selector(sendMail))
        
        expenseChart.isUserInteractionEnabled = false
        expenseChart.drawEntryLabelsEnabled = false
        expenseChart.drawHoleEnabled = true
        expenseChart.rotationAngle = 0
        expenseChart.rotationEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        customizeChart(expenseData: FirebaseHandler.shared.currentUser?.expenses ?? [])
    }
    
    private func customizeChart(expenseData: [Expense]) {
        guard !expenseData.isEmpty else {
            return
        }
        
        var expenses: [String: Int] = [:]
        var totalSum = 0
        for expense in expenseData {
            if expenses[expense.category.rawValue] == nil {
                expenses[expense.category.rawValue] = 0
            }
            // swiftlint:disable:next force_unwrapping
            expenses[expense.category.rawValue]! += expense.amount
            totalSum += expense.amount
        }
                
        var dataEntries: [ChartDataEntry] = []
        
        for expense in expenses {
            let dataEntry = PieChartDataEntry(value: Double(expense.value), label: expense.key, data: expense.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        
        pieChartDataSet.colors = randomColors(dataPoints: expenses.count)
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let format = NumberFormatter()
        format.numberStyle = .currency
        let formatter = DefaultValueFormatter(formatter: format)
        pieChartData.setValueFormatter(formatter)
        
        expenseChart.data = pieChartData
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
    
    @objc func sendMail() {
        let alertController = UIAlertController(title: "Support", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Support.addExpense.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: Support.refundMoney.rawValue, style: .default, handler: setComposerMessage))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        
        present(alertController, animated: true)
    }
    
    private func setComposerMessage(action: UIAlertAction) {
        guard MFMailComposeViewController.canSendMail() else {
            assertionFailure("Mail services are not available")
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([Support.Constants.email])
        if let title = action.title {
            switch title {
            case Support.addExpense.rawValue:
                composer.setSubject(title)
            case Support.refundMoney.rawValue:
                composer.setSubject(title)
            default:
                composer.setSubject(Support.other.rawValue)
            }
        }
        present(composer, animated: true)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let expenseVC = ViewControllerFactory.shared.viewController(for: .expense)
        navigationController?.pushViewController(expenseVC, animated: true)
    }
}

extension HomeViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard error == nil else {
            controller.dismiss(animated: true)
            return
        }
        
        controller.dismiss(animated: true)
    }
}
