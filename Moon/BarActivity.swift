//
//  BarActivity.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

class BarActivity2: Mappable {
    
    var barId: String? = nil
    var barName: String? = nil
    var time: NSDate? = nil
    var userName: String? = nil
    var userId: String? = nil
    
    required init?(_ map: Map){
    }
    
    func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userId = context.id
        }
        if map.JSONDictionary["time"] is String {
            self.time       <- (map["time"], DateTransformString)
        } else {
            self.time       <- (map["time"], DateTransformDouble)
        }
        self.barId      <- map["barID"]
        self.barName    <- map["barName"]
        
        self.userName   <- map["userName"]
    }
    
}
