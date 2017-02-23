//
//  BarActivity.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct BarActivity2: Mappable {
    
    var barId: String? = nil
    var barName: String? = nil
    var time: NSDate? = nil
    var userName: String? = nil
    var userId: String? = nil
    var likes: Int? = nil
    
    init(barID: String?, barName: String?, time: NSDate?) {
        self.barId = barID
        self.barName = barName
        self.time = time
    }
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.userId = context.id
        }
        
        self.time       <- (map["time"], DateTransfromDouble)
        self.barId      <- map["barID"]
        self.barName    <- map["barName"]
        self.likes      <- map["likes"]
        self.userName   <- map["userName"]
    }
    
}
