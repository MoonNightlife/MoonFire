//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 6/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct UserFull {
    var age: Int?
    var bio: String?
    var cityData: CityFull?
    var currentBarId: String?
    var email: String?
    var favoriteDrink: String?
    var friends: [Friends]?
    var gender: Gender?
    var name: String?
    var profilePicture: UIImage?
    var userName: String?
}

struct CityFull {
    var name: String?
    var picture: UIImage?
}

struct Friends {
    var username: String?
    var userId: String?
}

struct FriendRequest {
    var fromId: String?
    var toId: String?
    var fromUsername: String?
}

enum Gender {
    case Male
    case Female
}