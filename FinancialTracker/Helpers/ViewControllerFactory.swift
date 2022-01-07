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

enum ViewControllerType: String {
    case entry = "EntryVC"
    case register = "RegisterVC"
    case login = "LoginVC"
    case balance = "BalanceVC"
    case home = "HomeVC"
    case expense = "ExpenseVC"
}

extension ViewControllerType {
    func storyboardRepresentation() -> StoryboardRepresentation {
        return StoryboardRepresentation(bundle: nil, storyboardName: StoryBoardType.main.rawValue, storyboardId: self.rawValue)
    }
}

class ViewControllerFactory {
    private init () {}
    
    // Will be refractored from singleton in the future
    static let shared = ViewControllerFactory()
    private(set) var navController = UINavigationController()
    
    func viewController(for typeOfVC: ViewControllerType) -> UIViewController {
        let metadata = typeOfVC.storyboardRepresentation()
        let storyboard = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: metadata.storyboardId)
        return viewController
    }
}
