//
//  User.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 3.02.22.
//

import Foundation

struct User {
    let firstName: String
    let lastName: String
    let email: String
    let uid: String
    var balance: Double?
    var currency: Currency?
    var expenses: [Transaction] = []
    var incomes: [Transaction] = []
    var score: Double
    var premium: Bool
    
    init(firstName: String, lastName: String, email: String, uid: String, score: Double) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.uid = uid
        self.score = score
        self.premium = false
    }
}

extension User: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try values.decode(String.self, forKey: .firstName)
        lastName = try values.decode(String.self, forKey: .lastName)
        email = try values.decode(String.self, forKey: .email)
        uid = try values.decode(String.self, forKey: .uid)
        balance = try values.decodeIfPresent(Double.self, forKey: .balance)
        currency = try values.decodeIfPresent(Currency.self, forKey: .currency)
        expenses = try values.decodeIfPresent([Transaction].self, forKey: .expenses) ?? []
        incomes = try values.decodeIfPresent([Transaction].self, forKey: .incomes) ?? []
        score = try values.decode(Double.self, forKey: .score)
        premium = try values.decode(Bool.self, forKey: .premium)
    }
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, uid, balance, currency, expenses, score, premium, incomes
    }
}
