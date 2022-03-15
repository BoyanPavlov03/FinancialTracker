//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit
import Charts

private enum TimePeriodDivider: Int {
    case today
    case week
    case month
    case year
    case all
}

class HomeViewController: UIViewController {
    @IBOutlet var transactionChart: PieChartView!
    @IBOutlet var expenseDividerSegmentedControl: UISegmentedControl!
    @IBOutlet var expenseOrIncomeSegmentedControl: UISegmentedControl!
    
    var authManager: AuthManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Home"
        tabBarItem.image = UIImage(systemName: "house")
        let plusImage = UIImage(systemName: "plus")
        let addTransactionButton = UIBarButtonItem(image: plusImage, style: .plain, target: self, action: #selector(addTransactionButtonTapped))
        navigationItem.rightBarButtonItem = addTransactionButton
        
        checkIfPremium()
        
        transactionChart.highlightPerTapEnabled = false
        transactionChart.drawEntryLabelsEnabled = false
        transactionChart.drawHoleEnabled = true
        transactionChart.rotationAngle = 0
        transactionChart.rotationEnabled = false
        
        let format = NumberFormatter()
        format.numberStyle = .decimal
        transactionChart.data?.setValueFormatter(DefaultValueFormatter(formatter: format))
            
        authManager?.addDelegate(self)
    }
    
    private func checkIfPremium() {
        if let premium = authManager?.currentUser?.premium, premium, expenseDividerSegmentedControl.numberOfSegments == 2 {
            expenseDividerSegmentedControl.insertSegment(withTitle: "Week", at: 1, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Month", at: 2, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Year", at: 3, animated: true)
        }
    }
    
    private func expenseOrIncome(start: Date, end: Date) -> [Transaction] {
        var data: [Transaction] = []
        if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
            data = start.transactionBetweenTwoDates(till: end, data: authManager?.currentUser?.expenses ?? [])
        } else {
            data = start.transactionBetweenTwoDates(till: end, data: authManager?.currentUser?.incomes ?? [])
        }
        return data
    }
    
    private func periodDivider(_ period: Int) {
        switch period {
        case TimePeriodDivider.today.rawValue:
            let start = Date().startOfDay
            guard let end = Date().endOfDay else { return }
            updateChart(transactionData: expenseOrIncome(start: start, end: end))
        case TimePeriodDivider.week.rawValue:
            guard let premium = authManager?.currentUser?.premium, premium else {
                if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
                    updateChart(transactionData: authManager?.currentUser?.expenses ?? [])
                } else {
                    updateChart(transactionData: authManager?.currentUser?.incomes ?? [])
                }
                return
            }
            guard let start = Date().startOfWeek, let end = Date().endOfWeek else { return }
            updateChart(transactionData: expenseOrIncome(start: start, end: end))
        case TimePeriodDivider.month.rawValue:
            guard let start = Date().startOfMonth, let end = Date().endOfMonth else { return }
            updateChart(transactionData: expenseOrIncome(start: start, end: end))
        case TimePeriodDivider.year.rawValue:
            guard let start = Date().startOfYear, let end = Date().endOfYear else { return }
            updateChart(transactionData: expenseOrIncome(start: start, end: end))
        case TimePeriodDivider.all.rawValue:
            if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
                updateChart(transactionData: authManager?.currentUser?.expenses ?? [])
            } else {
                updateChart(transactionData: authManager?.currentUser?.incomes ?? [])
            }
        default:
            break
        }
    }
    
    private func updateChart(transactionData: [Transaction]) {
        guard !transactionData.isEmpty else {
            transactionChart.data = nil
            transactionChart.notifyDataSetChanged()
            return
        }
        
        var transactions: [String: Double] = [:]
        var totalSum = 0.0
        for transaction in transactionData {
            if transactions[transaction.category.getRawValue] == nil {
                transactions[transaction.category.getRawValue] = 0.0
            }
            // swiftlint:disable:next force_unwrapping
            transactions[transaction.category.getRawValue]! += transaction.amount
            totalSum += transaction.amount
        }
        let sortedTransactions = transactions.sorted { $0.key < $1.key }
                
        var dataEntries: [ChartDataEntry] = []
        
        for transaction in sortedTransactions {
            let dataEntry = PieChartDataEntry(value: transaction.value.round(to: 2), label: transaction.key, data: transaction.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        
        var colors: [UIColor] = []
        sortedTransactions.forEach { key, _ in
            if let category = ExpenseCategory(rawValue: key) {
                colors.append(category.color)
            } else if let category = IncomeCategory(rawValue: key) {
                colors.append(category.color)
            }
        }

        pieChartDataSet.colors = colors
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        transactionChart.data = pieChartData
        
        guard let symbol = authManager?.currentUser?.currency?.symbolNative else {
            return
        }
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Tamil Sangam MN", size: 25.0)]
        let myString = "\(totalSum.round(to: 2))\(String(describing: symbol))"
        let totalSumString = NSAttributedString(string: myString, attributes: attributes as [NSAttributedString.Key: Any])
        transactionChart.centerAttributedText = totalSumString
    }
    
    @objc private func addTransactionButtonTapped() {
        guard let transactionVC = ViewControllerFactory.shared.viewController(for: .transaction) as? TransactionViewController else {
            assertionFailure("Couldn't cast to TransactionViewController")
            return
        }
        
        transactionVC.authManager = authManager
        navigationController?.pushViewController(transactionVC, animated: true)
    }
    
    @IBAction func expenseOrIncomeControlDidChange(_ sender: UISegmentedControl) {
        periodDivider(expenseDividerSegmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func dividerControlDidChange(_ sender: UISegmentedControl) {
        periodDivider(sender.selectedSegmentIndex)
    }
}

extension HomeViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        dividerControlDidChange(expenseDividerSegmentedControl)
        checkIfPremium()
    }
}
