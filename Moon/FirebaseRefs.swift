//
//  FirebaseRefs.swift
//  Moon
//
//  Created by Evan Noble on 1/21/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation


struct FirebaseRefs {
    static let Cities = rootRef.child("cities")
    static let BarActivities = rootRef.child("barActivities")
    static let Users = rootRef.child("users")
    static let NotificationSettings = rootRef.child("notificationSettings")
    static let FriendRequest = rootRef.child("friendRequest")
    static let Usernames = rootRef.child("usernames")
    static let PhoneNumbers = rootRef.child("phoneNumbers")
    static let Friends = rootRef.child("friends")
    static let Bars = rootRef.child("bars")
}