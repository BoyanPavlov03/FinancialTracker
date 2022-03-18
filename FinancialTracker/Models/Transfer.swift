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
    var uid: String
    var transferType: TransferType
    var transferState: TransferState
    var fromUser: String
    var toUser: String
    var amount: Double
    var title: String
    var description: String
    var senderCurrencyRate: Double
    var receiverCurrencyRate: Double
    var date: String
    
    enum TransferKeys: String {
        case uid, transferType, transferState, fromUser, toUser, title, description, date, amount, senderCurrencyRate, receiverCurrencyRate
    }
    
    init(uid: String, transferType: TransferType, transferState: TransferState, fromUser: String, toUser: String, amount: Double, title: String, description: String, senderCurrencyRate: Double, receiverCurrencyRate: Double, date: String) {
        self.uid = uid
        self.fromUser = fromUser
        self.toUser = toUser
        self.transferType = transferType
        self.transferState = transferState
        self.amount = amount
        self.title = title
        self.description = description
        self.senderCurrencyRate = senderCurrencyRate
        self.receiverCurrencyRate = receiverCurrencyRate
        self.date = date
    }
}
