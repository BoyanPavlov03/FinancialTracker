//
//  Transfer.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 16.02.22.
//

import Foundation

enum TransferType: String, Codable {
    case send = "Send"
    case requestFromMe = "Request From Me"
    case requestToMe = "Request To Me"
    case receive = "Receive"
}

enum TransferState: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
}

struct Transfer: Codable, Equatable {
    let uid: String
    var transferType: TransferType
    let transferState: TransferState
    let fromUser: String
    let toUser: String
    let amount: Double
    let senderName: String
    let senderCurrencyRate: Double
    let receiverCurrencyRate: Double
    let date: String
    
    enum TransferKeys: String {
        case transferState, amount, receiverCurrencyRate
    }
}
