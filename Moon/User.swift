//
//  User.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

class User2: Mappable {
    
    var firstName:String? = nil
    var lastName:String? = nil
    
    required init?(_ pMap: Map){
    }
    
    func mapping(pMap: Map) {
        self.firstName  <- pMap["firstName"]
        self.lastName   <- pMap["lastName"]
    }
}




