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

let DateTransformDouble = TransformOf<NSDate, Double>(fromJSON: { (value: Double?) -> NSDate? in
    
    return NSDate(timeIntervalSince1970: value!)
    
    }, toJSON: { (value: NSDate?) -> Double? in
        // transform value from Int? to String?
        if let value = value {
            return  NSDate().timeIntervalSince1970
        }
        return nil
})

// TODO: Remove this string check once we clear bar activities
let DateTransformString = TransformOf<NSDate, String>(fromJSON: { (value: String?) -> NSDate? in
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

let BarSpecialTransform = TransformOf<BarSpecial, String>(fromJSON: { (value: String?) -> BarSpecial? in

        switch value! {
            case "Beer": return BarSpecial.Beer
            case "Wine": return BarSpecial.Wine
            case "Spirits": return BarSpecial.Spirits
            default: return nil
        }

    }, toJSON: { (value: BarSpecial?) -> String? in
        // transform value from Int? to String?
        if let value = value {
            return value.rawValue
        }
        return nil
})

let DayTransform = TransformOf<Day, String>(fromJSON: { (value: String?) -> Day? in
    
        switch value! {
            case "Monday": return Day.Monday
            case "Tuesday": return Day.Tuesday
            case "Wednesday": return Day.Wednesday
            case "Thursday": return Day.Thursday
            case "Friday": return Day.Friday
            case "Saturday": return Day.Saturday
            case "Sunday": return Day.Sunday
            case "Weekdays": return Day.Weekdays
            default: return nil
        }
 
    
    }, toJSON: { (value: Day?) -> String? in
        // transform value from Int? to String?
        if let value = value {
            return value.rawValue
        }
        return nil
})

let ProviderTransform = TransformOf<Provider, String>(fromJSON: { (value: String?) -> Provider? in
    
    switch value! {
    case "Firebase": return Provider.Firebase
    case "Facebook": return Provider.Facebook
    case "Google": return Provider.Google
    default: return nil
    }
    
    
    }, toJSON: { (value: Provider?) -> String? in
        // transform value from Int? to String?
        if let value = value {
            return value.rawValue
        }
        return nil
})

let GenderTransform = TransformOf<Gender, String>(fromJSON: { (value: String?) -> Gender? in
    
    switch value! {
        case "male" : return Gender.Male
        case "female": return Gender.Female
        default: return nil
    }
    
    
    }, toJSON: { (value: Gender?) -> String? in
        // transform value from Int? to String?
        if let value = value {
            value == .Male ? "male" : "female"
        }
        return nil
})



