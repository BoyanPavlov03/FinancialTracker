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
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        return ac
    }
}
