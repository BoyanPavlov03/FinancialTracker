//
//  Expense.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 3.02.22.
//

import UIKit

struct Expense: Codable {
    let amount: Double
    let date: String
    let category: Category
        
    enum CodingKeys: String, CodingKey {
        case amount
        case date
        case category
    }
}

enum Category: String, CaseIterable, Codable {
    case transport = "Transport"
    case grocery = "Grocery"
    
    case taxes = "Taxes"
    case utility = "Utility"
    case travel = "Travel"
    
    case other = "Other"
    
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
