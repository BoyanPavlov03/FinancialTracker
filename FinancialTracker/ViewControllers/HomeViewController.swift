//
//  HomeViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 29.12.21.
//

import UIKit
import Charts

class HomeViewController: UIViewController {
    @IBOutlet var expenseChart: PieChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        customizeChart(data: FirebaseHandler.shared.currentUser?.expenses)
    }
    
    func customizeChart(data: [Expense]?) {
        guard let data = data else {
            return
        }
        
        var expenses: [String: Int] = [:]
        var totalSum = 0
        var colors = Set<UIColor>()
        for expense in data {
            if expenses[expense.category] == nil {
                expenses[expense.category] = 0
            }
            // swiftlint:disable:next force_unwrapping
            expenses[expense.category]! += expense.amount
            totalSum += expense.amount
            
            for category in Category.allCases {
                if category.rawValue.compare(expense.category, options: .caseInsensitive) == .orderedSame {
                    colors.insert(category.color)
                }
            }
        }
                
        var dataEntries: [ChartDataEntry] = []
        
        for expense in expenses {
            let dataEntry = PieChartDataEntry(value: Double(expense.value), label: expense.key, data: expense.key as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "")
        pieChartDataSet.colors = Array(colors)
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let format = NumberFormatter()
        format.numberStyle = .currency
        let formatter = DefaultValueFormatter(formatter: format)
        pieChartData.setValueFormatter(formatter)
        
        expenseChart.data = pieChartData
        expenseChart.isUserInteractionEnabled = false
    }
        
    @objc func signOut() {
        FirebaseHandler.shared.signOut { firebaseError, _ in
            switch firebaseError {
            case .signOut(let error):
                guard let error = error else { return }
                self.present(UIAlertController.create(title: "Sign Out Error", message: error.localizedDescription), animated: true)
            case .database, .unknown, .access, .auth:
                // swiftlint:disable:next force_unwrapping
                assertionFailure("This error should not appear: \(firebaseError!.localizedDescription)")
                // swiftlint:disable:next unneeded_break_in_switch
                break
            case .none:
                break
            }
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let expenseVC = ViewControllerFactory.viewController(for: .expense)
        navigationController?.pushViewController(expenseVC, animated: true)
    }
}
