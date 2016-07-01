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
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .NoStyle
    return formatter
}

let defaultProfilePictureString = ""

func createUserFromSnap(snap: FDataSnapshot) -> UserFull {
    
    // Properties
    var birthday: NSDate?
    var bio: String?
    var cityData: CityFull?
    var currentBarId: String?
    var email: String?
    var favoriteDrink: String?
    var friends: [Friend]?
    var gender: Gender?
    var name: String?
    var profilePicture: UIImage?
    var username: String?
    var privacy: Bool?
    var barFeed: [BarFeed]?
    
    // Birthday
    if let birthdayTemp = snap.value["age"] as? String {
        birthday = createNSDateFromString(birthdayTemp, formatter: dateFormatter)
    } else {
        birthday = nil
    }
    
    // Bio
    if let bioTemp = snap.value["bio"] as? String {
        bio = bioTemp
    } else {
        bio = nil
    }
    
    // Current Bar Id
    if let currentBarIdTemp = snap.value["currentBar"] as? String {
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
    
    // Profile Picture
    if let profilePictureTemp = snap.value["profilePicture"] as? String {
        profilePicture = stringToUIImage(profilePictureTemp, defaultString: "")
    } else {
        profilePicture = nil
    }
    
    // Privacy
    if let privacyTemp = snap.value["privacy"] as? String {
        privacy = privacyStringToBool(privacyTemp)
    } else {
        privacy = nil
    }
    
    // Bar Feed
    let barFeedSnap: FDataSnapshot = snap.childSnapshotForPath("barFeed")
    if barFeedSnap.value is NSNull {
        barFeed = nil
    } else {
        barFeed = createBarFeedListFromSnap(barFeedSnap)
    }
    
    // Friends
    let friendSubSnap: FDataSnapshot = snap.childSnapshotForPath("friends")
    if friendSubSnap.value is NSNull {
        friends = nil
    } else {
        friends = createFriendArrayFromSnap(friendSubSnap)
    }
    
    // City Data
    let subSnap: FDataSnapshot = snap.childSnapshotForPath("cityData")
    if subSnap.value is NSNull {
        cityData = nil
    } else {
        cityData = createCityFromSnap(subSnap)
    }
    
    let user = UserFull(birthday: birthday, bio: bio, cityData: cityData, currentBarId: currentBarId, email: email, favoriteDrink: favoriteDrink, friends: friends, gender: gender, name: name, profilePicture: profilePicture, username: username, userId: snap.key, privacy: privacy, barFeed: barFeed)
    
    return user
}

func createBarFeedListFromSnap(snap: FDataSnapshot) -> [BarFeed]? {
    var barFeedTemp = [BarFeed]()
    for feed in snap.children {
        barFeedTemp.append(BarFeed(activityId: feed.key as String))
    }
    return barFeedTemp
}

func privacyStringToBool(string: String) -> Bool? {
    switch string {
    case "off":
        return false
    case "on":
        return true
    default:
        return nil
    }
}

func userToAnyObject(user: UserFull) -> [NSObject : AnyObject] {
    
    let userDataAsObject = ["age":dateToString(user.birthday),"bio":user.bio,"currentBar":user.currentBarId,"email":user.email,"favoriteDrink":user.favoriteDrink,"gender":genderToString(user.gender),"name":user.name,"profilePicture": imageToString(user.profilePicture) ?? defaultProfilePictureString,"username":user.username, "privacy":boolToString(user.privacy)]
    
    return userDataAsObject
}

func imageToString(image:UIImage) -> String? {
    let imageData = UIImageJPEGRepresentation(image,0.1)
    let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    return base64String
}

func boolToString(bool:Bool) -> String {
    if bool {
        return "yes"
    } else {
        return "no"
    }
}

func dateToString(date: NSDate) -> String? {
    let date = dateFormatter.stringFromDate(date)
    return date
}

func createFriendArrayFromSnap(snap: FDataSnapshot) -> [Friend]? {
    var friendsTemp = [Friend]()
    for friend in snap.children {
        if let username = friend.key {
            if let userIdTemp = (friend as! FDataSnapshot).value as? String {
                friendsTemp.append(Friend(username: username, userId: userIdTemp))
            }
        }
    }
    return friendsTemp
}

func createNSDateFromString(date: String, formatter: NSDateFormatter) -> NSDate? {
    formatter.dateStyle = .MediumStyle
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

func genderToString(gender: Gender) -> String {
    switch gender {
    case .Female:
        return "female"
    case .Male:
        return "male"
    }
}

func createCityFromSnap(snap: FDataSnapshot) -> CityFull? {
    if let name = snap.value["name"] as? String {
        if let image = snap.value["picture"] as? String {
            let cityDataTemp = CityFull(name: name, picture: stringToUIImage(image, defaultString: ""))
            return cityDataTemp
        }
    }
    return nil
}






