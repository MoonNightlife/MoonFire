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

let rootRef = FIRDatabase.database().reference()
let storageRef = FIRStorage.storage().reference() //FIRStorage.storage().reference()

var currentUser: FIRDatabaseReference {
    let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    let currentUser = rootRef.child("users").child(userID)
    return currentUser
}

let geoFire = GeoFire(firebaseRef: rootRef.child("geoFireRef"))
let geoFireCity = GeoFire(firebaseRef: rootRef.child("geoFireCity"))