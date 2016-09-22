//
//  Constants.swift
//  Moon
//
//  Created by Evan Noble on 8/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView

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
            titleColor: K.Color.CustomBlue
            
        )
        static let UserNamePromptApperance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: K.Font.FontName, size: K.Font.TitleFontSize)!,
            kTextFont: UIFont(name: K.Font.FontName, size: K.Font.SubTitleFontSize)!,
            kButtonFont: UIFont(name: K.Font.FontName, size: K.Font.ButtonFontSize)!,
            showCloseButton: false,
            showCircularIcon: false,
            contentViewColor: UIColor.whiteColor(),
            contentViewBorderColor: K.Color.CustomBlue,
            titleColor: K.Color.CustomBlue
        )

    }
    struct MapView {
        static let RadiusToMonitor = 4.0
    }
    struct Profile {
        static let CitySearchRadiusKilometers = 50.0
        static let MaxCharForBio = 25
        static let MaxCharForFavoriteDrink = 12
    }
    struct BarSearchViewController {
        static let BarSearchRadiusKilometers = 40.2336
        static let BarActivityHourOffset = -5
    }
    struct Utilities {
        static let SpecialsHourOffset = -5.0
    }
}
