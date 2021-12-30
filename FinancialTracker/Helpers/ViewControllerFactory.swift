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

enum TypeOfViewController {
    case navigation(TypeOfNavigationController)
    case entry
    case register
    case login
    case balance
    case home
    case expense
}

enum TypeOfNavigationController {
    case entry
    case balance
    case home
}

extension TypeOfViewController {
    func storyboardRepresentation() -> StoryboardRepresentation {
        switch self {
        case .navigation(let type):
            switch type {
            case .entry:
                return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "EntryNavigationVC")
            case .balance:
                return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "EntryNavigationVC")
            case .home:
                return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "HomeNavigationVC")
            }
        case .entry:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "EntryVC")
        case .register:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "RegisterVC")
        case .login:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "LoginVC")
        case .balance:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "BalanceVC")
        case .home:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "HomeVC")
        case .expense:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Main", storyboardId: "ExpenseVC")
        }
    }
}

class ViewControllerFactory: NSObject {
    static func viewController(for typeOfVC: TypeOfViewController) -> UIViewController {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId)
        return viewController
    }
    
    static func navController(for typeOfVC: TypeOfViewController) -> UINavigationController? {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId) as? UINavigationController else {
            assertionFailure("Couldn't cast to NavigationVC.")
            return nil
        }
        return navigationController
    }
}
