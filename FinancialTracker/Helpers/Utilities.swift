//
//  Utilities.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 7.01.22.
//

import Foundation
import UIKit

func randomColors(dataPoints: Int) -> [UIColor] {
    var colors: [UIColor] = []
    for _ in 0..<dataPoints {
        let red = Double(arc4random_uniform(256))
        let green = Double(arc4random_uniform(256))
        let blue = Double(arc4random_uniform(256))
        let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
        colors.append(color)
    }
    return colors
}
