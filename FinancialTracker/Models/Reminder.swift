//
//  Reminder.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 16.02.22.
//

import Foundation

enum TransferType: String, Codable {
    case send = "Send"
    case request = "Request"
    
    var index: Int {
        switch self {
        case .send:
            return 0
        case .request:
            return 1
        }
    }
}

struct Reminder: Codable, Equatable {
    var transferType: TransferType
    var description: String
    var date: String
    
    enum CodingKeys: String, CodingKey {
        case transferType, description, date
    }
    
    init(transferType: TransferType, description: String, date: String) {
        self.transferType = transferType
        self.description = description
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transferType = try values.decode(TransferType.self, forKey: .transferType)
        description = try values.decode(String.self, forKey: .description)
        date = try values.decode(String.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transferType, forKey: .transferType)
        try container.encode(description, forKey: .description)
        try container.encode(date, forKey: .date)
    }
}
