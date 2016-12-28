//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct CityData: Mappable {
    var cityId: String? = nil
    var name: String? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        
        self.cityId     <- map["cityId"]
        self.name       <- map["name"]
        
    }

}

struct User2: Mappable {
    
    var name: String?
    var username: String?
    var simLocation: SimLocation?
    var provider: Provider?
    var privacy: Bool? = false
    var sex: Sex?
    var friends: [String:String]?
    var favoriteBarId: String?
    var email: String?
    var currentBarId: String?
    var cityData: CityData?
    var barFeed: [String]?
    var birthday: String?
    var userId: String?
    var favoriteDrink: String?
    var bio: String?
    var phoneNumberStored: String?
    var phoneNumberGui: String?
    var password: String?
    
    init() {
        
    }
    
    init?(_ map: Map){
        if map.JSONDictionary["username"] == nil {
            return nil
        }
    }
    
    mutating func mapping(map: Map) {
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
        self.sex         <- (map["gender"], GenderTransform)
        //self.friends        <- map["friends.0"]
        self.favoriteBarId  <- map["favoriteBarId"]
        self.email          <- map["email"]
        self.currentBarId     <- map["currentBar"]
        self.cityData       <- map["cityData"]
        //self.barFeed        <- map["barFeed"]
        self.birthday                <- map["age"]
        self.phoneNumberStored  <- map["phoneNumberStored"]
        self.phoneNumberGui     <- map["phoneNumberGui"]
    }
}




