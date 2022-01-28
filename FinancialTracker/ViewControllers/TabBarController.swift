//
//  TabBarController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 27.01.22.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let currentUser = FirebaseHandler.shared.currentUser else {
            assertionFailure("User data is nil")
            return
        }
        
        if currentUser.premium {
            guard var viewControllers = self.viewControllers else { return }
            // Remove the premium tab as the user owns it
            viewControllers.remove(at: 3)
            self.viewControllers = viewControllers
        }
    }
    
}
