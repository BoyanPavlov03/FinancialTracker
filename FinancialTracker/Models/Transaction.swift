//
//  Expense.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 3.02.22.
//

import UIKit

protocol Transaction: Codable {
    func transactionType() -> String
}

struct Expense: Transaction {
    let amount: Double
    let date: String
    let category: ExpenseCategory
        
    enum CodingKeys: String, CodingKey {
        case amount
        case date
        case category
    }
    
    func transactionType() -> String {
        return "expense"
    }
}

struct Income: Transaction {
    let amount: Double
    let date: String
    let category: IncomeCategory
        
    enum CodingKeys: String, CodingKey {
        case amount
        case date
        case category
    }
    
    func transactionType() -> String {
        return "income"
    }
}
