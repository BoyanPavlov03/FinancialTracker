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
    // MARK: - Outlet properties
    @IBOutlet var transactionChart: PieChartView!
    @IBOutlet var expenseDividerSegmentedControl: UISegmentedControl!
    @IBOutlet var expenseOrIncomeSegmentedControl: UISegmentedControl!
    
    // MARK: - Properties
    var authManager: AuthManager?
    var selectedTransactions: [Transaction] = []
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Home"
        tabBarItem.image = UIImage(systemName: "house")
        let plusImage = UIImage(systemName: "plus")
        let addTransactionButton = UIBarButtonItem(image: plusImage, style: .plain, target: self, action: #selector(addTransactionButtonTapped))
        navigationItem.rightBarButtonItem = addTransactionButton
        
        checkIfPremium()
        
        transactionChart.highlightPerTapEnabled = true
        transactionChart.drawEntryLabelsEnabled = false
        transactionChart.drawHoleEnabled = true
        transactionChart.rotationAngle = 0
        transactionChart.rotationEnabled = false
        transactionChart.delegate = self
        
        let format = NumberFormatter()
        format.numberStyle = .decimal
        transactionChart.data?.setValueFormatter(DefaultValueFormatter(formatter: format))
            
        authManager?.addDelegate(self)
    }
    
    deinit {
        authManager?.removeDelegate(self)
    }
    
    // MARK: - Own methods
    private func checkIfPremium() {
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil.")
        }
        
        if currentUser.premium, expenseDividerSegmentedControl.numberOfSegments == 2 {
            expenseDividerSegmentedControl.insertSegment(withTitle: "Week", at: 1, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Month", at: 2, animated: true)
            expenseDividerSegmentedControl.insertSegment(withTitle: "Year", at: 3, animated: true)
        }
    }
    
    private func expenseOrIncome(start: Date, end: Date) -> [Transaction] {
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil.")
        }
        
        // If control is on 0 it should expenses and if on 1 - incomes
        if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
            return start.transactionBetweenTwoDates(till: end, data: currentUser.expenses)
        } else {
            return start.transactionBetweenTwoDates(till: end, data: currentUser.incomes)
        }
    }
    
    private func periodDivider(_ period: Int) {
        guard let currentUser = authManager?.currentUser else {
            fatalError("User data is nil.")
        }
        
        switch period {
        case TimePeriodDivider.today.rawValue:
            // Updating chart with all expenses or incomes for current day
            let start = Date().startOfDay
            guard let end = Date().endOfDay else { return }
            selectedTransactions = expenseOrIncome(start: start, end: end)
        case TimePeriodDivider.week.rawValue:
            // Updating chart with all expenses or incomes for current week
            if currentUser.premium == false {
                if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
                    selectedTransactions = currentUser.expenses
                } else {
                    selectedTransactions = currentUser.incomes
                }
                return
            }
            guard let start = Date().startOfWeek, let end = Date().endOfWeek else { return }
            selectedTransactions = expenseOrIncome(start: start, end: end)
        case TimePeriodDivider.month.rawValue:
            // Updating chart with all expenses or incomes for current month
            guard let start = Date().startOfMonth, let end = Date().endOfMonth else { return }
            
            selectedTransactions = expenseOrIncome(start: start, end: end)
        case TimePeriodDivider.year.rawValue:
            // Updating chart with all expenses or incomes for current year
            guard let start = Date().startOfYear, let end = Date().endOfYear else { return }
            selectedTransactions = expenseOrIncome(start: start, end: end)
        case TimePeriodDivider.all.rawValue:
            // Updating chart with all expenses or incomes
            if expenseOrIncomeSegmentedControl.selectedSegmentIndex == 0 {
                selectedTransactions = currentUser.expenses
            } else {
                selectedTransactions = currentUser.incomes
            }
        default:
            break
        }
        
        updateChart()
    }
    
    private func updateChart() {
        guard !selectedTransactions.isEmpty else {
            transactionChart.data = nil
            transactionChart.noDataText = "There are no transactions."
            transactionChart.notifyDataSetChanged()
            return
        }
        
        var transactions: [String: Double] = [:]
        var totalSum = 0.0
        // Unifiying all expenses/incomes from the same category into total sum
        // for when displaying on chart
        for transaction in selectedTransactions {
            if transactions[transaction.category.getRawValue] == nil {
                transactions[transaction.category.getRawValue] = 0.0
            }
            // swiftlint:disable:next force_unwrapping
            transactions[transaction.category.getRawValue]! += transaction.amount
            totalSum += transaction.amount
        }
        let sortedTransactions = transactions.sorted { $0.key < $1.key }
                
        var dataEntries: [ChartDataEntry] = []
        
        // Setting all entries for the PieChart with unified expenses/incomes
        for transaction in sortedTransactions {
            let dataEntry = PieChartDataEntry(value: transaction.value.round(to: 2), label: transaction.key, data: transaction.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        
        // Setting the specific color for each category to the the it's corresponding entry
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
            fatalError("User data is nil.")
        }
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Tamil Sangam MN", size: 25.0)]
        let myString = "\(totalSum.round(to: 2))\(String(describing: symbol))"
        let totalSumString = NSAttributedString(string: myString, attributes: attributes as [NSAttributedString.Key: Any])
        transactionChart.centerAttributedText = totalSumString
    }
    
    // MARK: - IBAction methods
    @IBAction func expenseOrIncomeControlDidChange(_ sender: UISegmentedControl) {
        periodDivider(expenseDividerSegmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func dividerControlDidChange(_ sender: UISegmentedControl) {
        periodDivider(sender.selectedSegmentIndex)
    }
    
    @objc private func addTransactionButtonTapped() {
        guard let transactionVC = ViewControllerFactory.shared.viewController(for: .transaction) as? TransactionViewController else {
            assertionFailure("Couldn't cast to TransactionViewController")
            return
        }
        
        transactionVC.authManager = authManager
        navigationController?.pushViewController(transactionVC, animated: true)
    }
}

// MARK: - DatabaseManagerDelegate
extension HomeViewController: DatabaseManagerDelegate {
    func databaseManagerDidUserChange(sender: DatabaseManager) {
        dividerControlDidChange(expenseDividerSegmentedControl)
        checkIfPremium()
    }
}

extension HomeViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let data = entry.data else {
            return
        }
        
        var transactionsByCategory: [Transaction] = []
        
        for transaction in selectedTransactions {
            if transaction.category.getRawValue == String(describing: data) {
                transactionsByCategory.append(transaction)
            }
        }
        
        // swiftlint:disable:next line_length
        guard let selectedTransactionsVC = ViewControllerFactory.shared.viewController(for: .selectedTransactions) as? SelectedTransactionsViewController else {
            assertionFailure("Couldn't cast to SelectedTransactionsViewController")
            return
        }
        
        selectedTransactionsVC.authManager = self.authManager
        selectedTransactionsVC.selectedTransactions = transactionsByCategory
        selectedTransactionsVC.category = String(describing: data)
        
        navigationController?.pushViewController(selectedTransactionsVC, animated: true)
        transactionChart.highlightValue(nil)
    }
}
