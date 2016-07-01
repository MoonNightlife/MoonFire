//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 6/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct UserFull {
    var birthday: NSDate!
    var bio: String!
    var cityData: CityFull!
    var currentBarId: String!
    var email: String!
    var favoriteDrink: String!
    var friends: [Friend]!
    var gender: Gender!
    var name: String!
    var profilePicture: UIImage!
    var username: String!
    var userId: String!
    var privacy: Bool!
    var barFeed: [BarFeed]!
}

struct CityFull {
    var name: String!
    var picture: UIImage!
}

struct BarFeed {
    var activityId: String!
}

struct Friend {
    var username: String!
    var userId: String!
}

struct FriendRequest {
    var fromId: String!
    var toId: String!
    var fromUsername: String!
}

enum Gender: String {
    case Male
    case Female
}