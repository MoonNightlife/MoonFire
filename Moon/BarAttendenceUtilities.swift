//
//  BarAttendenceUtilities.swift
//  Moon
//
//  Created by Evan Noble on 8/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation
import SwiftOverlays
import GooglePlaces

func checkIfAttendingBarWithId(Id: String, handler: (isGoing: Bool, oldBarRef: FIRDatabaseReference?)->()) {
    // This looks at the users profile and sees if he or she is attending the bar and then updating the button
    currentUser.child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if(!(snap.value is NSNull)) {
            if(snap.value as! String == Id) {
                handler(isGoing: true, oldBarRef: rootRef.child("bars").child(snap.value as! String))
            } else {
                handler(isGoing: false, oldBarRef: rootRef.child("bars").child(snap.value as! String))
            }
        } else {
            handler(isGoing: false, oldBarRef: nil)
        }
    }) { (error) in
        print(error.description)
    }
}

// Adds bar activity to firebase, also addeds bar ref to user as well as adding the reference to the bar activity to friends barFeeds
func addBarToUser(barId: String, barName: String, userName: String) {
    
    let activitiesRef = rootRef.child("barActivities")
    
    let currentTime = NSDate().timeIntervalSince1970
    
    currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
        
        // Save activity under barActivities
        let activity = ["barID": barId, "barName": barName, "time": currentTime, "userName": userName]
        activitiesRef.child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(activity)
        
        // Save reference for barActivity under current user
        currentUser.child("currentBar").setValue(barId)
        
        // Save reference for barActivity under each friends feed
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for child in snap.children {
                if let friend: FIRDataSnapshot = child as? FIRDataSnapshot {
                    rootRef.child("users").child(friend.value as! String).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                }
            }
            SwiftOverlays.removeAllBlockingOverlays()
            }, withCancelBlock: { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                print(error.description)
        })
        
    }) { (error) in
        SwiftOverlays.removeAllBlockingOverlays()
        print(error.description)
    }
}

// Removes all exsitance of the bar activity
func removeBarFromUsers() {
    
    
    // Remove bar reference from barActivities
    rootRef.child("barActivities").child(currentUser.key).removeValue()
    // Remove bar reference firom current user
    currentUser.child("currentBar").removeValue()
    
    // Remove bar activity from friend's feed
    currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
        for child in snap.children {
            if let friend: FIRDataSnapshot = child as? FIRDataSnapshot {
                rootRef.child("users").child(friend.value as! String).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
            }
        }
        SwiftOverlays.removeAllBlockingOverlays()
        }, withCancelBlock: { (error) in
            SwiftOverlays.removeAllBlockingOverlays()
            print(error.description)
    })
}

// Creates a new bar and sets init information
func createBarAndIncrementUsersGoing(lat: CLLocationDegrees, long: CLLocationDegrees, barName: String, barId: String) {
    // Find the radius of bar for region monitoring
    let geoCoder = CLGeocoder()
    let location = CLLocation(latitude: lat, longitude: long)
    geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
        if placemarks?.count > 1 {
            print("too many placemarks for convertion")
        } else if error == nil {
            let placemark = (placemarks![0] as CLPlacemark)
            let circularRegion = placemark.region as? CLCircularRegion
            let radius = circularRegion?.radius
            // This is where bars are created in firebase, add more moon data here
            let initBarData = ["usersGoing" : 1, "usersThere" : 0, "radius" : radius!, "barName" : barName]
            rootRef.child("bars").child(barId).setValue(initBarData)
        }  else {
            print(error?.description)
        }
        
        // This creates a geoFire location
        geoFire.setLocation(CLLocation(latitude: lat, longitude: long), forKey: barId) { (error) in
            if error != nil {
                print(error.description)
                
            }
        }
    }
}


func changeAttendanceStatus(barId: String, userName: String) {
    checkIfAttendingBarWithId(barId) { (isGoing, oldBarRef) in
        if !isGoing {
            GMSPlacesClient().lookUpPlaceID(barId) { (place, error) in
                if let error = error {
                    SwiftOverlays.removeAllBlockingOverlays()
                    print(error.description)
                }
                if let place = place {
                    rootRef.child("bars").child(barId).observeSingleEventOfType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull) {
                            incrementUsersGoing(snap.ref)
                        } else {
                            createBarAndIncrementUsersGoing(place.coordinate.latitude, long: place.coordinate.longitude, barName: place.name, barId: place.placeID)
                        }
                        
                        addBarToUser(place.placeID, barName: place.name, userName: userName)
                        // If the user is going to a different bar and chooses to go to the bar displayed, decreament the old bar by one
                        if let oldRef = oldBarRef {
                            decreamentUsersGoing(oldRef)
                            // Toggle friends feed about updated barActivity
                            currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                                for child in snap.children {
                                    if let friend: FIRDataSnapshot = child as? FIRDataSnapshot {
                                        rootRef.child("users").child(friend.value as! String).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                                    }
                                }
                                SwiftOverlays.removeAllBlockingOverlays()
                                }, withCancelBlock: { (error) in
                                    SwiftOverlays.removeAllBlockingOverlays()
                                    print(error.description)
                            })
                        }
                        }, withCancelBlock: { (error) in
                            SwiftOverlays.removeAllBlockingOverlays()
                            print(error.description)
                    })
                }
            }
        } else {
            decreamentUsersGoing(oldBarRef!)
            removeBarFromUsers()
        }
    }
    
}