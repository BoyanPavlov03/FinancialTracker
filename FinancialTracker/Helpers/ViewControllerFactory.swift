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
    case navigation(NavigationControllerType)
    case entry
    case register
    case login
    case balance
    case home
    case expense
    
    var value: String {
        switch self {
        case .navigation:
            return "Navigation"
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

enum NavigationControllerType: String {
    case entry
    case balance
    case home
    
    var value: String {
        switch self {
        case .home:
            return "HomeNavigationVC"
        case .balance:
            return "BalanceNavigationVC"
        case .entry:
            return "EntryNavigationVC"
        }
    }
}

extension ViewControllerType {
    func storyboardRepresentation() -> StoryboardRepresentation {
        switch self {
        case .navigation(let type):
            return StoryboardRepresentation(bundle: nil, storyboardName: StoryBoardType.main.rawValue, storyboardId: type.value)
        default:
            return StoryboardRepresentation(bundle: nil, storyboardName: StoryBoardType.main.rawValue, storyboardId: self.value)
        }
    }
}

class ViewControllerFactory {
    static func viewController(for typeOfVC: ViewControllerType) -> UIViewController {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId)
        return viewController
    }
    
    static func navController(for typeOfVC: ViewControllerType) -> UINavigationController? {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId) as? UINavigationController else {
            assertionFailure("Couldn't cast to NavigationVC.")
            return nil
        }
        return navigationController
    }
}
