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
    
    init() {
        
    }
    
    init?(_ map: Map){
        if map.JSONDictionary["username"] == nil {
            return nil
        }
    }
    
    mutating func mapping(map: Map) {
        
        if let context = map.context as? Context {
            self.userID = context.id!
        }
        
        self.firstName     <- map["firstName"]
        self.lastName      <- map["lastName"]
        self.username      <- map["username"]
        self.privacy       <- map["privacy"]
    }
}

struct UserProfile: Mappable {
    
    var simLocation: SimLocation?
    var sex: Sex?
    var favoriteBarId: String?
    var currentBarId: String?
    var cityData: CityData?
    var birthday: String?
    var favoriteDrink: String?
    var bio: String?
    var phoneNumber: String?
    
    init() {
    
    }
    
    init?(_ map: Map){

    }
    
    mutating func mapping(map: Map) {
        self.bio                <- map["bio"]
        self.favoriteDrink      <- map["favoriteDrink"]
        self.simLocation        <- map["simLocation"]
        self.sex                <- (map["gender"], GenderTransform)
        self.favoriteBarId      <- map["favoriteBarId"]
        self.currentBarId       <- map["currentBar"]
        self.cityData           <- map["cityData"]
        self.birthday           <- map["age"]
        self.phoneNumber        <- map["phoneNumber"]
    }
}

struct User2: Mappable {
    
    var userSnapshot: UserSnapshot?
    var userProfile: UserProfile?
    
    init() {
        userSnapshot = UserSnapshot()
        userProfile = UserProfile()
        userSnapshot?.privacy = false
    }
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        self.userProfile    <- map["profile"]
        self.userSnapshot   <- map["snapshot"]
    }
}




