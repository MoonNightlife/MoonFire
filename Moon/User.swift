//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 3/31/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

struct User {
  let uid: String
  let email: String
  
  // Initialize from Firebase
  init(authData: FAuthData) {
    uid = authData.uid
    email = authData.providerData["email"] as! String
  }
  
  // Initialize from arbitrary data
  init(uid: String, email: String) {
    self.uid = uid
    self.email = email
  }
}