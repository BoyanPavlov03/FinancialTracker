//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit
import Charts
import MessageUI

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
        guard MFMailComposeViewController.canSendMail() else {
            assertionFailure("Mail services are not available")
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["support_financialTracker@gmail.com"])
        
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
        
        switch result {
        case .cancelled:
            print("Cancelled")
        case .saved:
            print("Saved")
        case .sent:
            print("Sent")
        case .failed:
            print("Failed")
        @unknown default:
            fatalError("Unknown case.")
        }
        
        controller.dismiss(animated: true)
    }
}
