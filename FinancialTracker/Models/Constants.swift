//
//  Constants.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 21.02.22.
//

import Foundation

struct Constants {
    struct UserInfo {
        static let token = "token"
        static let amount = "amount"
        static let description = "description"
        static let transferType = "transferType"
    }
    
    struct Share {
        static let shareText = "Wanna keep track of your finance life. Click the link to install this new amazing app on the App Store:"
        static let shareLink = "https://app.bitrise.io/artifact/113971239/p/a364f20e4db777fa7e692386989d3053"
    }
    
    struct Support {
        static let addExpense = "Problem adding an expense"
        static let refundMoney = "Want a refund"
        static let other = "Other"
            
        static let email = "support_financialTracker@gmail.com"
    }
}
