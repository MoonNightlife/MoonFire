//
//  FriendRequest.swift
//  Moon
//
//  Created by Evan Noble on 12/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct FriendRequest: Mappable {
    
    var userID: String?
    var username: String?
    var name: String?
    
    
    init?(_ map: Map){
        
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userID = context.id!
        }
        self.username     <- map["barName"]
        self.name         <- map["radius"]
    }
    
}