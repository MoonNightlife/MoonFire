//
//  Structs.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct City {
    var image: String?
    var name: String?
}

struct barActivity {
    let userName: String?
    let userID: String?
    let barName: String?
    let barID: String?
    let time: String?
}

struct Special {
    var associatedBarId: String
    var type: BarSpecial
    var description: String
    var dayOfWeek: Day
    var barName: String
    func toString() -> [String:String] {
        return ["associatedBarId":"\(associatedBarId)","type":"\(type)","description":"\(description)","dayOfWeek":"\(dayOfWeek)","barName":"\(barName)"]
    }
}

struct User {
    var name: String?
    var userID: String?
    var profilePicture: UIImage?
    var privacy: String?
}

struct Photo {
    var id: String
    var title: String
    var farm: String
    var secret: String
    var server: String
    var imageURL: NSURL {
        get {
            let url = NSURL(string: "http://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_m.jpg")!
            return url
        }
    }
}