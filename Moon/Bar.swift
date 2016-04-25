//
//  Bar.swift
//  Moon
//
//  Created by Evan Noble on 3/31/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

struct Bar {
    let name: String
    let phoneNumber: String
    let url: String
    let usersGoing: Int
    
    init(name: String, phoneNumber: String, url: String, usersGoing: Int) {
        self.name = name
        self.phoneNumber = url
        self.url = url
        self.usersGoing = usersGoing
    }
}