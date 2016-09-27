//
//  Extentions.swift
//  Moon
//
//  Created by Evan Noble on 9/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView

//MARK: - Class Extension
extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat, length: CGFloat, label: UILabel) {
        
        let border = CALayer()
        
        
        switch edge {
        case UIRectEdge.Top:
            border.frame = CGRectMake(self.frame.size.width - length, 0, length, thickness)
            break
        case UIRectEdge.Bottom:
            border.frame = CGRectMake(0, CGRectGetHeight(self.frame), length, thickness)
            break
        case UIRectEdge.Left:
            border.frame = CGRectMake(0, 0, thickness, length)
            break
        case UIRectEdge.Right:
            border.frame = CGRectMake(self.frame.size.width, -8, thickness, length)
            break
        default:
            break
        }
        
        border.backgroundColor = color.CGColor;
        
        self.addSublayer(border)
    }
    
}

