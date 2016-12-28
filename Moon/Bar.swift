//
//  Bar.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct Bar2: Mappable {
    
    var barId: String? = nil
    var barName: String? = nil
    var radius: Double? = nil
    var usersGoing: Int? = nil
    var usersThere: Int? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.barId = context.id!
        }
        self.barName        <- map["barName"]
        self.radius         <- map["radius"]
        self.usersGoing     <- map["usersGoing"]
        self.usersThere     <- map["usersThere"]
    }
    
}