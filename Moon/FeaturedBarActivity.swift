//
//  FeaturedBarActivity.swift
//  Moon
//
//  Created by Evan Noble on 8/11/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct FeaturedBarActivity: Mappable {
    
    var description: String? = nil
    var date: String? = nil
    var time: String? = nil
    var cityId: String? = nil
    var featuredId: String? = nil
    var pictureUrl: String? = nil
    var barId: String? = nil
    var name: String? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.featuredId = context.id
        }
        
        self.description    <- map["description"]
        self.date           <- map["date"]
        self.time           <- map["time"]
        self.cityId         <- map["cityId"]
        self.pictureUrl     <- map["pictureUrl"]
        self.barId          <- map["barId"]
        self.name           <- map["barName"]
    }
}