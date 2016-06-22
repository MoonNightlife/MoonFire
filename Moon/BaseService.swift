//
//  BaseService.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import GeoFire

let baseUrl = "https://moonnightlife.firebaseio.com"
let rootRef = Firebase(url: baseUrl)
var currentUsersID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String

var currentUser: Firebase {
    let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    let currentUser = Firebase(url: "\(rootRef)").childByAppendingPath("users").childByAppendingPath(userID)
    return currentUser!
}

let geoFire = GeoFire(firebaseRef: rootRef.childByAppendingPath("geoFireRef"))
let geoFireCity = GeoFire(firebaseRef: rootRef.childByAppendingPath("geoFireCity"))