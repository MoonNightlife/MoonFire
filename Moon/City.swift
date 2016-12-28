//
//  City.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

import ObjectMapper

struct City2: Mappable {
    
    var cityId: String? = nil
    var lat: Double? = nil
    var long: Double? = nil
    var name: String? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.cityId = context.id!
        }
        self.name  <- map["name"]
        self.lat   <- map["lat"]
        self.long  <- map["long"]
    }
    
}