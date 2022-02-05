//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit
import Charts

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

    var databaseManager: DatabaseManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
        
        self.tabBarItem.image = UIImage(systemName: "house")
        
        expenseChart.isUserInteractionEnabled = false
        expenseChart.drawEntryLabelsEnabled = false
        expenseChart.drawHoleEnabled = true
        expenseChart.rotationAngle = 0
        expenseChart.rotationEnabled = false
        
        updateChart()
        
        databaseManager?.addDelegate(self)
    }
    
    func updateChart() {
        let expenseData = databaseManager?.currentUser?.expenses ?? []
        
        guard !expenseData.isEmpty else {
            return
        }
        
        var expenses: [String: Double] = [:]
        var totalSum = 0.0
        for expense in expenseData {
            if expenses[expense.category.rawValue] == nil {
                expenses[expense.category.rawValue] = 0.0
            }
            // swiftlint:disable:next force_unwrapping
            expenses[expense.category.rawValue]! += expense.amount.round(to: 2)
            totalSum += expense.amount
        }
                
        var dataEntries: [ChartDataEntry] = []
        
        for expense in expenses {
            let dataEntry = PieChartDataEntry(value: expense.value, label: expense.key, data: expense.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        
        var colors: [UIColor] = []
        expenses.forEach { key, _ in
            guard let category = Category(rawValue: key) else {
                assertionFailure("Category doesn't exist.")
                return
            }
            colors.append(category.color)
        }

        pieChartDataSet.colors = colors
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let format = NumberFormatter()
        format.numberStyle = .decimal
        let formatter = DefaultValueFormatter(formatter: format)
        pieChartData.setValueFormatter(formatter)
        
        expenseChart.data = pieChartData
    }
    
    @objc func signOut() {
        databaseManager?.authManager?.signOut { firebaseError, _ in
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
    
    @IBAction func addButtonTapped(_ sender: Any) {
        guard let expenseVC = ViewControllerFactory.shared.viewController(for: .expense) as? ExpenseViewController else {
            assertionFailure("Couldn't cast to ExpenseViewController")
            return
        }
        
        expenseVC.databaseManager = databaseManager
        navigationController?.pushViewController(expenseVC, animated: true)
    }
}

extension HomeViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        updateChart()
    }
}
