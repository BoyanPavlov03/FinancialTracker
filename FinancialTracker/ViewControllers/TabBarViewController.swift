//
//  TabBarViewController.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 18.01.22.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let homeVC = ViewControllerFactory.shared.viewController(for: .home)
        let homeNav = UINavigationController(rootViewController: homeVC)
        self.viewControllers = [homeNav]
    }
}
