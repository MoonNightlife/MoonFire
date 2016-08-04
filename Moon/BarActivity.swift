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
    
    required init?(_ pMap: Map){
    }
    
    func mapping(pMap: Map) {
        self.barId      <- pMap["firstName"]
        self.barName    <- pMap["lastName"]
        self.time       <- (pMap["time"], DateTransform)
        self.userName   <- pMap["userName"]
    }
    
}
