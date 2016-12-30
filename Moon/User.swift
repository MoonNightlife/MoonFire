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

// This type of condensed user is used to in table views when we dont need to display the full profile
struct UserSnapshot: Mappable {
    
    var firstName: String?
    var lastName: String?
    var username: String?
    var userID: String?
    var privacy: Bool?
    var profilePictureThumnail: UIImage?
    
    init?(_ map: Map){
    
    }
    
    mutating func mapping(map: Map) {
        
        if let context = map.context as? Context {
            self.userID = context.id!
        }
        
        self.firstName       <- map["firstName"]
        self.lastName      <- map["lastName"]
        self.username   <- map["username"]
        self.privacy     <- map["privacy"]
    }
}

struct UserProfile: Mappable {
    var
}

struct User2: Mappable {
    
    var name: String?
    var firstName: String?
    var lastName: String?
    var username: String?
    var simLocation: SimLocation?
    var provider: Provider?
    var privacy: Bool?
    var sex: Sex?
    var favoriteBarId: String?
    var email: String?
    var currentBarId: String?
    var cityData: CityData?
    var birthday: String?
    var userId: String?
    var favoriteDrink: String?
    var bio: String?
    var phoneNumberStored: String?
    var phoneNumberGui: String?
    // Password is not stored in database. This property is only used when creating an account
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
        
        self.bio                <- map["bio"]
        self.favoriteDrink      <- map["favoriteDrink"]
        self.name               <- map["name"]
        self.firstName          <- map["firstName"]
        self.lastName           <- map["lastName"]
        self.username           <- map["username"]
        self.simLocation        <- map["simLocation"]
        self.provider           <- (map["provider"], ProviderTransform)
        self.privacy            <- map["privacy"]
        self.sex                <- (map["gender"], GenderTransform)
        self.favoriteBarId      <- map["favoriteBarId"]
        self.email              <- map["email"]
        self.currentBarId       <- map["currentBar"]
        self.cityData           <- map["cityData"]
        self.birthday           <- map["age"]
        self.phoneNumberStored  <- map["phoneNumberStored"]
        self.phoneNumberGui     <- map["phoneNumberGui"]
    }
}




