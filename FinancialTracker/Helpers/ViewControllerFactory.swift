//
//  ViewControllerFactory.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 30.12.21.
//

import Foundation
import UIKit

struct StoryboardRepresentation {
    let bundle: Bundle?
    let storyboardName: String
    let storyboardId: String
}

enum StoryBoardType: String {
    case main = "Main"
}

enum ViewControllerType {
    case entry
    case register
    case login
    case balance
    case home
    case expense
    
    var value: String {
        switch self {
        case .entry:
            return "EntryVC"
        case .register:
            return "RegisterVC"
        case .login:
            return "LoginVC"
        case .balance:
            return "BalanceVC"
        case .home:
            return "HomeVC"
        case .expense:
            return "ExpenseVC"
        }
    }
}

extension ViewControllerType {
    func storyboardRepresentation() -> StoryboardRepresentation {
        return StoryboardRepresentation(bundle: nil, storyboardName: StoryBoardType.main.rawValue, storyboardId: self.value)
    }
}

class ViewControllerFactory {
    private init () {}
    
    // Will be refractored from singleton in the future
    static let shared = ViewControllerFactory()
    let navController = UINavigationController()
    
    func viewController(for typeOfVC: ViewControllerType) -> UIViewController {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId)
        return viewController
    }
}
