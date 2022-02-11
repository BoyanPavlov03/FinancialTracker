//
//  Expense.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 3.02.22.
//

import UIKit

struct Transaction: Codable {
    var amount: Double
    var date: String
    var category: Category
    
    enum CodingKeys: String, CodingKey {
        case amount, date, category
    }
    
    init(amount: Double, date: String, category: Category) {
        self.amount = amount
        self.date = date
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(Double.self, forKey: .amount)
        date = try values.decode(String.self, forKey: .date)
        if let expense = try? values.decode(ExpenseCategory.self, forKey: .category) {
            category = expense
        } else {
            category = try values.decode(IncomeCategory.self, forKey: .category)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        if let expense = category as? ExpenseCategory {
            try container.encode(expense, forKey: .category)
        } else if let income = category as? IncomeCategory {
            try container.encode(income, forKey: .category)
        }
    }
}
