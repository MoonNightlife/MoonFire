//
//  Photo.swift
//  Moon
//
//  Created by Evan Noble on 6/7/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

struct Photo {
    var id: String
    var title: String
    var farm: String
    var secret: String
    var server: String
    var imageURL: NSURL {
        get {
            let url = NSURL(string: "http://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_m.jpg")!
            return url
        }
    }
}