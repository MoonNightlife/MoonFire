//
//  Special.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

class Special2: Mappable {
    
    var barId: String? = nil
    var barName: String? = nil
    var dayOfWeek: Day? = nil
    var description: String? = nil
    var type: BarSpecial? = nil
    var specialId: String? = nil
    var likes: Int? = nil
    
    required init?(_ map: Map){
    }
    
    func mapping(map: Map) {
        if let context = map.context as? Context {
            self.specialId = context.id!
        }
        self.barId          <- map["barID"]
        self.barName        <- map["barName"]
        self.dayOfWeek      <- (map["dayOfWeek"], DayTransform)
        self.description    <- map["description"]
        self.type           <- (map["type"], BarSpecialTransform)
        self.likes          <- map["likes"]
    }
    
}