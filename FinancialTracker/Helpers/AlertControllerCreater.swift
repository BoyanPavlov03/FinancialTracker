//
//  AlertControllerCreater.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 17.12.21.
//

import Foundation
import UIKit

extension UIAlertController {
    static func create(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        return alertController
    }
}
