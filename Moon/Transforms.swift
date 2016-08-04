//
//  Transforms.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

let dateFormatter = NSDateFormatter()

let DateTransform = TransformOf<NSDate, String>(fromJSON: { (value: String?) -> NSDate? in
    // Transform value from String? to Int?
    dateFormatter.timeStyle = .FullStyle
    dateFormatter.dateStyle = .FullStyle
    
    return dateFormatter.dateFromString(value!)
    }, toJSON: { (value: NSDate?) -> String? in
        // transform value from Int? to String?
        if let value = value {
            return dateFormatter.stringFromDate(value)
        }
        return nil
})