//
//  Structs.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView
import ObjectMapper

struct K {
    struct Font {
        static let FontName =  "Roboto-Bold"
        static let TitleFontSize: CGFloat = 20.0
        static let SubTitleFontSize: CGFloat = 14.0
        static let ButtonFontSize: CGFloat = 16.0
    }
    struct Color {
        static let CustomGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        static let CustomBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
    }
    struct Apperances {
        static let NormalApperance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: K.Font.FontName, size: K.Font.TitleFontSize)!,
            kTextFont: UIFont(name: K.Font.FontName, size: K.Font.SubTitleFontSize)!,
            kButtonFont: UIFont(name: K.Font.FontName, size: K.Font.ButtonFontSize)!,
            showCloseButton: true,
            showCircularIcon: false,
            contentViewColor: UIColor.whiteColor(),
            contentViewBorderColor: K.Color.CustomBlue,
            titleColor: K.Color.CustomGray
        )
    }
    struct MapView {
        static let RadiusToMonitor = 4.0
    }
}

struct SimLocation {
    var lat: Double?
    var long: Double?
    var name: String?
}

struct Context: MapContext {
    var id: String?
}

struct City {
    var image: String?
    var name: String?
    var long: Double?
    var lat: Double?
    var id: String?
}

struct barActivity {
    let userName: String?
    let userID: String?
    let barName: String?
    let barID: String?
    let time: String?
}

struct Special {
    var associatedBarId: String
    var type: BarSpecial
    var description: String
    var dayOfWeek: Day
    var barName: String
    func toString() -> [String:String] {
        return ["associatedBarId":"\(associatedBarId)","type":"\(type)","description":"\(description)","dayOfWeek":"\(dayOfWeek)","barName":"\(barName)"]
    }
}

struct User {
    var name: String?
    var userID: String?
    var profilePicture: UIImage?
    var privacy: Bool?
}

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

