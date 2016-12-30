//
//  NSDateExtensions.swift
//  Moon
//
//  Created by Evan Noble on 12/7/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

extension NSDate {
    
    func convertDateToMediumStyleString() -> String {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        return dateFormatter.stringFromDate(self)
        
    }
}