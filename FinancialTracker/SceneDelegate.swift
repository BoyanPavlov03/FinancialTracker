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
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
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
                if let alert = UIAlertController.create(basedOnAuthError: authError) {
                    self.window?.rootViewController?.present(alert, animated: true)
                    return
                }
                
                guard let entryVC = ViewControllerFactory.shared.viewController(for: .entry) as? EntryViewController else {
                    assertionFailure("Couldn't cast to EntryViewController.")
                    return
                }
                
                entryVC.authManager = self.authManager
                navVC.pushViewController(entryVC, animated: true)
                window.rootViewController = navVC
            }
            
            self.window = window
            self.window?.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        startDate = Date.init()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // timeIntervalSinceNow is greater than timeActive, so i multiply by -1
        let timeActive = startDate.timeIntervalSinceNow * -1
        authManager.addScoreToCurrentUser(basedOn: timeActive) { authError, _ in
            if let alert = UIAlertController.create(basedOnAuthError: authError) {
                self.window?.rootViewController?.present(alert, animated: true)
                return
            }
        }
    }

}
