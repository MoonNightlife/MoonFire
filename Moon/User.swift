//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

class CityData: Mappable {
    var cityId: String? = nil
    var name: String? = nil
    
    required init?(_ map: Map){
    }
    
    func mapping(map: Map) {
        
        self.cityId     <- map["cityId"]
        self.name       <- map["name"]
        
    }

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
    var currentBarId: String? = nil
    var cityData: CityData? = nil
    var barFeed: [String]? = nil
    var age: String? = nil
    var userId: String? = nil
    var favoriteDrink: String? = nil
    var bio: String? = nil
    var phoneNumber: String? = nil
    
    
    required init?(_ map: Map){
    }
    
    func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userId = context.id!
        }
        
        self.bio            <- map["bio"]
        self.favoriteDrink  <- map["favoriteDrink"]
        self.name           <- map["name"]
        self.username       <- map["username"]
        self.simLocation    <- map["simLocation"]
        self.provider       <- (map["provider"], ProviderTransform)
        self.privacy        <- map["privacy"]
        self.gender         <- (map["gender"], GenderTransform)
        //self.friends        <- map["friends.0"]
        self.favoriteBarId  <- map["favoriteBarId"]
        self.email          <- map["email"]
        self.currentBarId     <- map["currentBar"]
        self.cityData       <- map["cityData"]
        //self.barFeed        <- map["barFeed"]
        self.age            <- map["age"]
        self.phoneNumber    <- map["phoneNumber"]
    }
}




