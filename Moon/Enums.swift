//
//  Enums.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

enum Day: String {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
    case Weekdays
}

enum BarSpecial: String {
    case Wine
    case Beer
    case Spirits
}

enum Provider: String {
    case Facebook
    case Google
    // Email
    case Firebase
}

enum Sex: Int {
    case Male = 0
    case Female = 1
    case None = 2
    var stringValue: String {
        switch self {
        case .Male:
            return "male"
        case .Female:
            return "female"
        case .None:
            return "none"
        }
    }
}

enum HeartColor {
    case Red
    case Gray
}

