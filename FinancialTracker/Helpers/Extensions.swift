//
//  Extensions.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 7.01.22.
//

import Foundation
import UIKit

var today: Date {
    return Date.init()
}

extension Date {
    var startOfWeek: Date? {
        let calendar = Calendar(identifier: .iso8601)
        guard let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return calendar.date(byAdding: .day, value: 0, to: monday)
    }
    
    var endOfWeek: Date? {
        let calendar = Calendar(identifier: .iso8601)
        guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return calendar.date(byAdding: .day, value: 7, to: sunday)
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    var startOfMonth: Date? {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)
    }
    
    var endOfMonth: Date? {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        guard let startOfMonth = startOfMonth else { return nil }
        return Calendar.current.date(byAdding: components, to: startOfMonth)
    }
    
    var startOfYear: Date? {
        let components = Calendar.current.dateComponents([.year], from: Date())
        guard let startOfYear = Calendar.current.date(from: components) else { return nil }
        return startOfYear
    }
    
    var endOfYear: Date? {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.year = 1
        components.day = -1
        guard let startOfYear = startOfYear else { return nil }
        return Calendar.current.date(byAdding: components, to: startOfYear)
    }
    
    func formatDate(_ format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }
    
    func expensesBetweenTwoDates(till endDate: Date, expenses: [Expense]) -> [Expense] {
        var newExpenses: [Expense] = []
        for expense in expenses {
            if let date = stringToDate(expense.date) {
                if date.isBetweeen(date: self, andDate: endDate) {
                    newExpenses.append(expense)
                }
            }
        }
        
        return newExpenses
    }
    
    func stringToDate(_ string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss, MMM dd, yyyy"
        
        return dateFormatter.date(from: string)
    }
}

extension UIAlertController {
    static func create(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        return alertController
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
