//
//  CityUtilities.swift
//  Moon
//
//  Created by Evan Noble on 8/11/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper


// MARK: - City locater
func queryForNearbyCities(location: CLLocation, promtUser: Bool) {
    counter = 0
    foundAllCities = (false,0)
    self.surroundingCities.removeAll()
    // Get user simulated location if choosen, but if there isnt one then use location services on the phone
    currentUser.child("simLocation").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if !(snap.value is NSNull), let city = snap.value as? [String : AnyObject] {
            
            let city = Mapper<City2>().map(city)
            
            if let city = city {
                if let long = city.long, let lat = city.lat {
                    let simulatedLocation = CLLocation(latitude: lat, longitude: long)
                    print(simulatedLocation)
                    self.circleQuery = geoFireCity.queryAtLocation(simulatedLocation, withRadius: K.Profile.CitySearchRadiusKilometers)
                }
            }
            
        } else {
            self.circleQuery = geoFireCity.queryAtLocation(location, withRadius: K.Profile.CitySearchRadiusKilometers)
        }
        let handle = self.circleQuery!.observeEventType(.KeyEntered) { (key, location) in
            self.foundAllCities.1 += 1
            self.getCityInformation(key)
        }
        self.handles.append(handle)
        self.circleQuery!.observeReadyWithBlock {
            self.foundAllCities.0 = true
            // If there is no simulated location and we can't find a city near the user then prompt them with a choice
            // to go to settings and pick a city named location
            if self.foundAllCities.1 == 0 {
                getCityPictureForCityId("-KKFSTnyQqwgQzFmEjcj" , imageView: self.cityCoverImage)
                self.cityText.text = "Unknown City"
                let cityData = ["name":"Unknown City","cityId":"-KKFSTnyQqwgQzFmEjcj"]
                currentUser.child("cityData").setValue(cityData)
                
                if promtUser {
                    self.promptUser()
                }
            }
        }
    })
}

func promptUser() {
    let alertview = SCLAlertView(appearance: K.Apperances.NormalApperance)
    alertview.addButton("Settings", action: {
        self.performSegueWithIdentifier("showSettingsFromProfile", sender: self)
    })
    alertview.showNotice("Not in supported city", subTitle: "Moon is currently not avaible in your city, but you can select a city from user settings")
}