//
//  AppDelegate.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotificationsUI

struct Constants {
    static let token = "token"
    static let amount = "amount"
    static let description = "description"
    static let type = "type"
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var authMananger: AuthManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        authMananger = AuthManager()
        authMananger?.checkAuthorisedState { _ in return }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let type = userInfo[Constants.type] as? String, let description = userInfo[Constants.description] as? String else {
            completionHandler(.noData)
            return
        }
    
        guard let amount = userInfo[Constants.amount] as? Substring, let amountValue = Double(amount) else {
            completionHandler(.noData)
            return
        }
        
        guard let transferType = TransferType(rawValue: type) else {
            completionHandler(.failed)
            return
        }
        
        authMananger?.setReminderToCurrentUser(type: transferType, description: description, completionHandler: { firebaseError, _ in
            if let firebaseError = firebaseError {
                assertionFailure(firebaseError.localizedDescription)
                completionHandler(.failed)
                return
            }
            if transferType == .send {
                let category = IncomeCategory.transfer
                self.authMananger?.addTransactionToCurrentUser(amountValue, category: category, completionHandler: { firebaseError, _ in
                    if let firebaseError = firebaseError {
                        assertionFailure(firebaseError.localizedDescription)
                        completionHandler(.failed)
                        return
                    }

                    completionHandler(.newData)
                })
            } else {
                completionHandler(.newData)
            }
        })
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("Firebase registration token: \(String(describing: fcmToken))")
            let FCMTokenKey = User.CodingKeys.FCMToken.rawValue
            let dataDict: [String: String] = [Constants.token: fcmToken]
            NotificationCenter.default.post(
                name: Notification.Name(FCMTokenKey),
                object: nil,
                userInfo: dataDict
            )
            UserDefaults.standard.set(fcmToken, forKey: FCMTokenKey)
        }
    }
}
