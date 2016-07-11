//
//  Bar.swift
//  Moon
//
//  Created by Evan Noble on 6/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct Bar {
    var barName: String?
    var radius: Double?
    var usersGoing: Int?
    var usersThere: Int?
}

struct BarActivity {
    var barId: String?
    var barName: String?
    var time: NSDate?
    var nameOfUser: String?
}

struct SpecialFull {
    var barID: String?
    var barName: String?
    var dayOfWeek: Day?
    var description: String?
    var type: BarSpecial?
}

enum Day: String {
    case Monday
    case Tuesday
    case Wednesday
    case Thuresday
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