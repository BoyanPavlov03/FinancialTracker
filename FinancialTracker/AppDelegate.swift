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

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var authMananger: AuthManager!
    
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
        // Calling this function to check if there is an user currently logged in and get his data
        authMananger.checkAuthorisedState { _, _ in return }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let transferTypeRawValue = userInfo[Constants.UserInfo.transferType] as? String else {
            completionHandler(.noData)
            return
        }
        
        guard let description = userInfo[Constants.UserInfo.description] as? String else {
            completionHandler(.noData)
            return
        }
    
        guard let amount = userInfo[Constants.UserInfo.amount] as? String else {
            completionHandler(.noData)
            return
        }

        guard let transferType = TransferType(rawValue: transferTypeRawValue), let amountValue = Double(amount) else {
            completionHandler(.failed)
            return
        }
        
        authMananger.setReminderToCurrentUser(transferType: transferType, description: description, completionHandler: { firebaseError, _ in
            if let firebaseError = firebaseError {
                assertionFailure(firebaseError.localizedDescription)
                completionHandler(.failed)
                return
            }
            if transferType == .send {
                let category = IncomeCategory.transfer
                self.authMananger.addTransactionToCurrentUser(amount: amountValue, category: category, completionHandler: { firebaseError, _ in
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
            let dataDict: [String: String] = [Constants.UserInfo.token: fcmToken]
            
            // Posting token to firebase server
            NotificationCenter.default.post(
                name: Notification.Name.FCMToken,
                object: nil,
                userInfo: dataDict
            )
            UserDefaults.standard.set(fcmToken, forKey: FCMTokenKey)
        }
    }
}
