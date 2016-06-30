//
//  File.swift
//  Moon
//
//  Created by Evan Noble on 6/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

var dateFormatter: NSDateFormatter {
    let formatter = NSDateFormatter()
    return formatter
}

func createUserFromSnap(snap: FDataSnapshot) -> UserFull {
    
    // Properties
    var birthday: NSDate?
    var bio: String?
    var cityData: CityFull?
    var currentBarId: String?
    var email: String?
    var favoriteDrink: String?
    var friends: [Friends]?
    var gender: Gender?
    var name: String?
    var profilePicture: UIImage?
    var username: String?
    
    // Birthday
    if let birthdayTemp = snap.value["age"] as? String {
        birthday = createNSDateFromString(birthdayTemp, formatter: dateFormatter)
    } else {
        birthday = nil
    }
    
    // Bio
    if let bioTemp = snap.value["age"] as? String {
        bio = bioTemp
    } else {
        bio = nil
    }
    
    // Current Bar Id
    if let currentBarIdTemp = snap.value["currentBarId"] as? String {
        currentBarId = currentBarIdTemp
    } else {
        currentBarId = nil
    }
    
    // Email
    if let emailTemp = snap.value["email"] as? String {
        email = emailTemp
    } else {
        email = nil
    }
    
    // Favorite Drink
    if let favoriteDrinkTemp = snap.value["favoriteDrink"] as? String {
        favoriteDrink = favoriteDrinkTemp
    } else {
        favoriteDrink = nil
    }
    
    // Gender
    if let genderTemp = snap.value["gender"] as? String {
        gender = stringToGender(genderTemp)
    } else {
        gender = nil
    }
    
    // Name
    if let nameTemp = snap.value["name"] as? String {
        name = nameTemp
    } else {
        name = nil
    }
    
    // Username
    if let usernameTemp = snap.value["username"] as? String {
        username = usernameTemp
    } else {
        username = nil
    }
    
    
    
    // City Data
    let subSnap: FDataSnapshot = snap.childSnapshotForPath("cityData")
    if subSnap.value is NSNull {
        cityData = nil
    } else {
        cityData = createCityFromSnap(subSnap)
    }
    
    let user = UserFull(birthday: birthday, bio: bio, cityData: cityData, currentBarId: currentBarId, email: email, favoriteDrink: favoriteDrink, friends: friends, gender: gender, name: name, profilePicture: profilePicture, username: username)
    
    return user
}

func createNSDateFromString(date: String, formatter: NSDateFormatter) -> NSDate? {
    formatter.dateStyle = .LongStyle
    return formatter.dateFromString(date)
}

func stringToGender(gender: String) -> Gender? {
    switch gender {
    case "male":
        return Gender.Male
    case "female":
        return Gender.Female
    default:
        return nil
    }
}

func createCityFromSnap(snap: FDataSnapshot) -> CityFull? {
    if let name = snap.value["name"] as? String {
        if let image = snap.value["image"] as? String {
            let cityDataTemp = CityFull(name: name, picture: stringToUIImage(image, defaultString: ""))
            return cityDataTemp
        }
    }
    return nil
}






