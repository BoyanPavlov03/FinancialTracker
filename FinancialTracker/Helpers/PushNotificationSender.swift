//
//  PushNotificationSender.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 13.02.22.
//

import Foundation
import UserNotificationsUI

class PushNotificatonSender {
    static func sendPushNotification(to token: String, title: String, body: String, type: ReminderType) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        guard let url = URL(string: urlString) else { return }
        let paramString: [String: Any] = [
            "content_available": true,
            "notification": [
                "title": title,
                "body": body
            ],
            "data": [
                "type": type.rawValue
            ],
            "to": token
        ]
        
        // Server key deleted for commit
        // swiftlint:disable:next line_length
        let serverKey = "AAAAbFv41p0:APA91bHdeRgPGSZyDulG6uCFvRWhDdkfcecPoxK9r0j3e_d1ETFqdz2yyRjfTlpoTZwNlxvdTo8OhuVgSuccrBFWZ-J0AdjoQ3h0ra05u16J9ZlwDqWwY_P_D-pQOEjsOk9SSXQ_daY7"
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
