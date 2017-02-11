//
//  Structs.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView
import ObjectMapper


struct SimLocation: Mappable {
    var lat: Double? = nil
    var long: Double? = nil
    var name: String? = nil
    
    init?(_ map: Map) {
    }
    
    mutating func mapping(map: Map) {
        self.lat    <- map["lat"]
        self.long   <- map["long"]
        self.name   <- map["name"]
    }
}

struct SimpleUser {
    var name: String?
    var userID: String?
    var privacy: Bool?
}

struct Context: MapContext {
    var id: String?
}

struct SpecialContext: MapContext {
    var barID: String
    var specialID: String
}

struct City {
    var image: String?
    var name: String?
    var long: Double?
    var lat: Double?
    var id: String?
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

