//
//  Transfer.swift
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

struct Transfer: Codable, Equatable {
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
}
