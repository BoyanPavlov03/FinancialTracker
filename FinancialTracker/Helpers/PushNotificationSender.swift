//
//  PushNotificationSender.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 13.02.22.
//

import Foundation
import UserNotificationsUI

class PushNotificatonSender {
    static func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        guard let url = URL(string: urlString) else { return }
        let paramString: [String: Any] = [
                            "to": token,
                            "notification": [
                                "title": title,
                                "body": body
                            ]
        ]
        
        // Server key deleted for commit
        let serverKey = ""
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request as URLRequest) { _, _, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            }
        }.resume()
    }
}
