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
