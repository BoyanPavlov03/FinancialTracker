//
//  PushNotificationSender.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 13.02.22.
//

import Foundation
import UserNotificationsUI

class PushNotificatonSender {
    static func sendPushNotificationForMoneyTransfer(to token: String, title: String, body: String, amount: Double, transferType: TransferType, completionHandler: @escaping (Error?) -> Void) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        guard let url = URL(string: urlString) else { return }
        let paramString: [String: Any] = [
            "content_available": true,
            "notification": [
                "title": title,
                "body": body
            ],
            "data": [
                Constants.UserInfo.transferType: transferType.rawValue,
                Constants.UserInfo.description: body,
                Constants.UserInfo.amount: amount
            ],
            "to": token
        ]
        
        #warning("DONT COMMIT KEY")
        let serverKey = ""
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request as URLRequest) { _, _, error in
            if let error = error {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }.resume()
    }
}
