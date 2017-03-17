//
//  Special.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct Special2: Mappable {
    
    var barId: String? = nil
    var barName: String? = nil
    var dayOfWeek: Day? = nil
    var description: String? = nil
    var type: BarSpecial? = nil
    var specialId: String? = nil
    var likes: [String]? = nil
    
    init?(_ map: Map){
    }
    
    init(partialSpecial: Special2, likes: [String]) {
        self.barId = partialSpecial.barId
        self.barName = partialSpecial.barName
        self.dayOfWeek = partialSpecial.dayOfWeek
        self.description = partialSpecial.description
        self.type = partialSpecial.type
        self.specialId = partialSpecial.specialId
        self.likes = likes
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? SpecialContext {
            self.barId = context.barID
            self.specialId = context.specialID
        }
        self.dayOfWeek      <- (map["dayOfWeek"], DayTransform)
        self.description    <- map["description"]
        self.type           <- (map["alcoholType"], BarSpecialTransform)
    }
    
}