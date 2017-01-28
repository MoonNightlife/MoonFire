//
//  NotificationSettings.swift
//  Moon
//
//  Created by Evan Noble on 1/27/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct NotificationSettings: Mappable {
    
    var userID: String? = nil
    var friendsGoingOut: Bool? = nil
    var peopleLikingStatus: Bool? = nil
    
    init(userID: String) {
        self.userID = userID
        self.friendsGoingOut = true
        self.peopleLikingStatus = true
    }
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userID = context.id!
        }
        self.peopleLikingStatus     <- map["peopleLikingStatus"]
        self.friendsGoingOut        <- map["friendsGoingOut"]
    }

}