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
    
    var cityId: String!
    var lat: Double!
    var long: Double!
    var name: String!
    
    init(name: String) {
        self.name = name
    }
    
    init?(_ map: Map){
        
        // Check if a required "name", "lat", "long", "cityId" property exists within the JSON.
        if map.JSONDictionary["name"] == nil && map.JSONDictionary["lat"] == nil && map.JSONDictionary["long"] == nil && (map.context as? Context)?.id == nil {
            return nil
        }
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