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
        print("User info: \(userInfo)")
        completionHandler(.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("Firebase registration token: \(String(describing: fcmToken))")
            let dataDict: [String: String] = ["token": fcmToken]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: dataDict
            )
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        }
    }
}
