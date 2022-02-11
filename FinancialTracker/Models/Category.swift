//
//  Income+Category.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 9.02.22.
//

import UIKit

protocol Category {
    var getRawValue: String { get }
}

enum ExpenseCategory: String, CaseIterable, Category, Codable {
    case transport = "Transport"
    case grocery = "Grocery"
    
    case taxes = "Taxes"
    case utility = "Utility"
    case travel = "Travel"
    
    case other = "Other"
    
    var getRawValue: String {
        return self.rawValue
    }
    
    var color: UIColor {
        switch self {
        case .transport:
            return UIColor(red: CGFloat(10.0/255), green: CGFloat(140.0/255), blue: CGFloat(50.0/255), alpha: 1)
        case .grocery:
            return UIColor(red: CGFloat(150.0/255), green: CGFloat(30.0/255), blue: CGFloat(10.0/255), alpha: 1)
        case .other:
            return UIColor(red: CGFloat(20.0/255), green: CGFloat(10.0/255), blue: CGFloat(160.0/255), alpha: 1)
        case .taxes:
            return UIColor(red: CGFloat(180.0/255), green: CGFloat(140.0/255), blue: CGFloat(10.0/255), alpha: 1)
        case .utility:
            return UIColor(red: CGFloat(5.0/255), green: CGFloat(160.0/255), blue: CGFloat(160.0/255), alpha: 1)
        case .travel:
            return UIColor(red: CGFloat(130.0/255), green: CGFloat(10.0/255), blue: CGFloat(170.0/255), alpha: 1)
        }
    }
}

enum IncomeCategory: String, CaseIterable, Category, Codable {
    case salary = "Salary"
    case gift = "Gifts"
    
    case interest = "Interest"
    case items = "Selling Items"
    case government = "Government Payments"
    
    case other = "Other"
    
    var getRawValue: String {
        return self.rawValue
    }
    
    var color: UIColor {
        switch self {
        case .salary:
            return UIColor(red: CGFloat(10.0/255), green: CGFloat(140.0/255), blue: CGFloat(50.0/255), alpha: 1)
        case .gift:
            return UIColor(red: CGFloat(150.0/255), green: CGFloat(30.0/255), blue: CGFloat(10.0/255), alpha: 1)
        case .other:
            return UIColor(red: CGFloat(20.0/255), green: CGFloat(10.0/255), blue: CGFloat(160.0/255), alpha: 1)
        case .interest:
            return UIColor(red: CGFloat(180.0/255), green: CGFloat(140.0/255), blue: CGFloat(10.0/255), alpha: 1)
        case .items:
            return UIColor(red: CGFloat(5.0/255), green: CGFloat(160.0/255), blue: CGFloat(160.0/255), alpha: 1)
        case .government:
            return UIColor(red: CGFloat(130.0/255), green: CGFloat(10.0/255), blue: CGFloat(170.0/255), alpha: 1)
        }
    }
}
