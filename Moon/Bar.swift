//
//  Bar.swift
//  Moon
//
//  Created by Evan Noble on 8/4/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper

struct BarInfo: Mappable {
    var barName: String? = nil
    var phoneNumber: String? = nil
    var website: String? = nil
    var address: String? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        self.barName        <- map["barName"]
        self.phoneNumber    <- map["phoneNumber"]
        self.website        <- map["website"]
        self.address        <- map["address"]
    }
}

struct BarData: Mappable {
    
    var usersGoing: Int? = nil
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        self.usersGoing     <- map["usersGoing"]
    }
}

struct Bar2: Mappable {
    
    var barId: String? = nil
    var barInfo: BarInfo?
    var barData: BarData?
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        if let context = map.context as? Context {
            self.barId = context.id!
        }
        self.barInfo        <- map["barInfo"]
        self.barData        <- map["barData"]
    }
    
}