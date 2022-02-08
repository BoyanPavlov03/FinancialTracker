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
    @IBOutlet var expenseDividerSegmentedControl: UISegmentedControl!
    
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"
        self.tabBarItem.image = UIImage(systemName: "house")
    
        checkIfPremium()
        
        expenseChart.isUserInteractionEnabled = false
        expenseChart.drawEntryLabelsEnabled = false
        expenseChart.drawHoleEnabled = true
        expenseChart.rotationAngle = 0
        expenseChart.rotationEnabled = false
        
        dividerControlDidChange(expenseDividerSegmentedControl)
        
        authManager?.addDelegate(self)
    }
    
    private func checkIfPremium() {
        if let premium = authManager?.currentUser?.premium, premium, expenseDividerSegmentedControl.numberOfSegments == 2 {
            expenseDividerSegmentedControl.insertSegment(withTitle: "Week", at: 1, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Month", at: 2, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Year", at: 3, animated: true)
        }
    }
    
    @IBAction func dividerControlDidChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            let start = Date().startOfDay
            guard let end = Date().endOfDay else { return }
            let expenses = start.expensesBetweenTwoDates(till: end, expenses: authManager?.currentUser?.expenses ?? [])
            updateChart(expenseData: expenses)
        case 1:
            guard let premium = authManager?.currentUser?.premium, premium else {
                updateChart(expenseData: authManager?.currentUser?.expenses ?? [])
                return
            }
            guard let start = Date().startOfWeek else { return }
            guard let end = Date().endOfWeek else { return }
            let expenses = start.expensesBetweenTwoDates(till: end, expenses: authManager?.currentUser?.expenses ?? [])
            updateChart(expenseData: expenses)
        case 2:
            guard let start = Date().startOfMonth else { return }
            guard let end = Date().endOfMonth else { return }
            let expenses = start.expensesBetweenTwoDates(till: end, expenses: authManager?.currentUser?.expenses ?? [])
            updateChart(expenseData: expenses)
        case 3:
            guard let start = Date().startOfYear else { return }
            guard let end = Date().endOfYear else { return }
            let expenses = start.expensesBetweenTwoDates(till: end, expenses: authManager?.currentUser?.expenses ?? [])
            updateChart(expenseData: expenses)
        case 4:
            updateChart(expenseData: authManager?.currentUser?.expenses ?? [])
        default:
            break
        }
    }
    
    func updateChart(expenseData: [Expense]) {
        guard !expenseData.isEmpty else {
            expenseChart.data = nil
            expenseChart.notifyDataSetChanged()
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
        let sortedExpenses = expenses.sorted { $0.key < $1.key }
        
        var dataEntries: [ChartDataEntry] = []
        
        for expense in sortedExpenses {
            let dataEntry = PieChartDataEntry(value: expense.value, label: expense.key, data: expense.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        
        var colors: [UIColor] = []
        sortedExpenses.forEach { key, _ in
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
    
    @IBAction func addButtonTapped(_ sender: Any) {
        guard let expenseVC = ViewControllerFactory.shared.viewController(for: .expense) as? ExpenseViewController else {
            assertionFailure("Couldn't cast to ExpenseViewController")
            return
        }
        
        expenseVC.authManager = authManager
        navigationController?.pushViewController(expenseVC, animated: true)
    }
}

extension HomeViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        dividerControlDidChange(expenseDividerSegmentedControl)
        checkIfPremium()
    }
}
