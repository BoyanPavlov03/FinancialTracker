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
        
        expenseChart.isUserInteractionEnabled = false
        expenseChart.drawEntryLabelsEnabled = false
        expenseChart.drawHoleEnabled = true
        expenseChart.rotationAngle = 0
        expenseChart.rotationEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        customizeChart(data: FirebaseHandler.shared.currentUser?.expenses ?? [])
    }
    
    private func customizeChart(data: [Expense]) {
        guard !data.isEmpty else {
            return
        }
        
        var expenses: [String: Int] = [:]
        var totalSum = 0
        for expense in data {
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
        
    private func randomColors(dataPoints: Int) -> [UIColor] {
        var colors: [UIColor] = []
        for _ in 0..<dataPoints {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
        }
        return colors
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
        let expenseVC = ViewControllerFactory.shared.viewController(for: .expense)
        navigationController?.pushViewController(expenseVC, animated: true)
    }
}
