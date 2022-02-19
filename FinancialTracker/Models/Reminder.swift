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
    var type: TransferType
    var description: String
    var date: String
    
    enum CodingKeys: String, CodingKey {
        case type, description, date
    }
    
    init(type: TransferType, description: String, date: String) {
        self.type = type
        self.description = description
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(TransferType.self, forKey: .type)
        description = try values.decode(String.self, forKey: .description)
        date = try values.decode(String.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(date, forKey: .date)
    }
}
