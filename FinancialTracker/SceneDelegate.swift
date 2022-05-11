//
//  SceneDelegate.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 10.12.21.
//

import UIKit

private var startDate = Date()

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private let authManager = AuthManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
            
        let window = UIWindow(windowScene: windowScene)
        
        let navVC = ViewControllerFactory.shared.navController
                
        authManager.checkAuthorisedState { authError, user in
            if let user = user {
                if user.balance != nil {
                    guard let tabBarVC = ViewControllerFactory.shared.viewController(for: .tabBar) as? TabBarController else {
                        assertionFailure("Couldn't cast to TabBarController.")
                        return
                    }
                    
                    tabBarVC.setAuthManager(self.authManager, accountCreated: false)
                    window.rootViewController = tabBarVC
                } else {
                    guard let balanceVC = ViewControllerFactory.shared.viewController(for: .balance) as? BalanceViewController else {
                        assertionFailure("Couldn't cast to BalanceViewController.")
                        return
                    }
                    
                    balanceVC.authManager = self.authManager
                    navVC.pushViewController(balanceVC, animated: true)
                    window.rootViewController = navVC
                }
            } else {
                guard authError == nil else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."
                    
                    self.window?.rootViewController?.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
                
                guard let loginVC = ViewControllerFactory.shared.viewController(for: .login) as? LoginViewController else {
                    assertionFailure("Couldn't cast to LoginViewController.")
                    return
                }
                
                loginVC.authManager = self.authManager
                navVC.pushViewController(loginVC, animated: true)
                window.rootViewController = navVC
            }
            
            self.window = window
            self.window?.makeKeyAndVisible()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Checking whether there is user before starting the timer
        if authManager.currentUser != nil {
            startDate = Date.init()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Checking whether there is user before trying to send score to firebase
        if authManager.currentUser != nil {
            // timeIntervalSinceNow is greater than timeActive, so i multiply by -1
            let timeActive = startDate.timeIntervalSinceNow * -1
            authManager.addScoreToCurrentUser(basedOn: timeActive) { authError, success in
                guard success else {
                    let alertTitle = authError?.title ?? "Unknown Error"
                    let alertMessage = authError?.message ?? "This error should not appear."
                    
                    self.window?.rootViewController?.present(UIAlertController.create(title: alertTitle, message: alertMessage), animated: true)
                    return
                }
            }
        }
    }

}
