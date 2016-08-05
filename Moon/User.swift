//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct CityData {
    var cityId: String?
    var name: String?
}

class User2: Mappable {
    
    var name: String? = nil
    var username: String? = nil
    var simLocation: SimLocation? = nil
    var provider: Provider? = nil
    var privacy: Bool? = nil
    var gender: Gender? = nil
    var friends: [String:String]? = nil
    var favoriteBarId: String? = nil
    var email: String? = nil
    var currentBar: String? = nil
    var cityData: CityData? = nil
    var barFeed: [String]? = nil
    var age: String? = nil
    var userId: String? = nil
    
    required init?(_ map: Map){
    }
    
    func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userId = context.id!
        }
        self.name           <- map["name"]
        self.username       <- map["username"]
        //self.simLocation    <- map["sim"]
        self.provider       <- map["provider"]
        self.privacy        <- map["privacy"]
        self.gender         <- map["gender"]
        //self.friends        <- map["friends.0"]
        self.favoriteBarId  <- map["favoriteBarId"]
        self.email          <- map["email"]
        self.currentBar     <- map["currentBar"]
        self.cityData       <- map["cityData"]
        //self.barFeed        <- map["barFeed"]
        self.age            <- map["age"]
    }
}




