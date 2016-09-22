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
import ObjectMapper

// Increases users going to a certain bar
func incrementUsersGoing(barRef: FIRDatabaseReference) {
    
    barRef.child("usersGoing").runTransactionBlock { (currentData) -> FIRTransactionResult in
        var value = currentData.value as? Int
        if (value == nil) {
            value = 0
        }
        currentData.value = value! + 1
        return FIRTransactionResult.successWithValue(currentData)
    }
}

// Decreament users going to a certain bar
func decreamentUsersGoing(barRef: FIRDatabaseReference) {
    barRef.child("usersGoing").runTransactionBlock { (currentData) -> FIRTransactionResult in
        var value = currentData.value as? Int
        if (value == nil) {
            value = 0
        }
        currentData.value = value! - 1
        return FIRTransactionResult.successWithValue(currentData)
    }
}

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
func addBarToUser(barId: String, barName: String, userName: String, handler: (finsihed: Bool) -> ()) {
    
    let activitiesRef = rootRef.child("barActivities")
    
    let currentTime = NSDate().timeIntervalSince1970
    
    currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
        
        // Save activity under barActivities
        let activity = ["barID": barId, "barName": barName, "time": currentTime, "userName": userName]
        activitiesRef.child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(activity)
        
        // Save reference for barActivity under current user
        currentUser.child("currentBar").setValue(barId)
        
        // Once the activity has been added to the database then the bar count can be updated
        handler(finsihed: true)
        
      
        // Save reference for barActivity under each friends feed
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            // Array to hold friendIds
            var friendIds = [String]()
            
            for child in snap.children {
                if let friend: FIRDataSnapshot = child as? FIRDataSnapshot {
                    rootRef.child("users").child(friend.value as! String).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                    friendIds.append(friend.value as! String)
                }
            }
            
            filterArrayForPeopleThatAcceptFriendsGoingOutNotifications(friendIds, handler: { (filteredFriends) in
                if !filteredFriends.isEmpty {
                    sendPush(false, badgeNum: 1, groupId: "Friends Going Out", title: "Moon", body: "Your friend " + userName + " is going out to " + barName, customIds: filteredFriends, deviceToken: "nil")
                }
            })
            
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
func removeBarFromUsers(oldBarRef: FIRDatabaseReference) {
    
    
    // Remove bar reference from barActivities
    rootRef.child("barActivities").child(currentUser.key).removeValue()
    // Decrement the number of users under bar profile so app knows to search through bar activties again
    decreamentUsersGoing(oldBarRef)
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

/**
 Check to see if the bar activity should be displayed on the activity feed. The bar activity must have a timestamp for today with a five hour offset
 - Author: Evan Noble
 - Parameters:
    - barRef: The ref to the special
 */
func seeIfShouldDisplayBarActivity(barActivity: BarActivity2) -> Bool {
    
    let betweenTwelveAMAndFiveAMNextDay = (barActivity.time?.isGreaterThanDate(NSDate().addHours(19).beginningOfDay()) == true) && (barActivity.time?.isLessThanDate(NSDate().addHours(19).beginningOfDay().addHours(5)) == true)
    let betweenFiveAmAndTwelveAMFirstDay = ((barActivity.time?.isGreaterThanDate(NSDate().addHours(-5).beginningOfDay().addHours(5))) == true) && ((barActivity.time?.isLessThanDate(NSDate().addHours(-5).endOfDay())) == true)

    if betweenFiveAmAndTwelveAMFirstDay || betweenTwelveAMAndFiveAMNextDay
    {
        return true
    }
    
    return false
}

/**
 Gets number of users going to a certain bar based off the number of bar activities.
 - Author: Evan Noble
 - Parameters: 
    - barId: The Id for the bar you want the number of users for
 - Returns: Handler that returns the number of users
 */
func getNumberOfUsersGoingBasedOffBarValidBarActivities(barId: String, handler: (numOfUsers: Int)->()) {
    rootRef.child("barActivities").queryOrderedByChild("barID").queryEqualToValue(barId).observeSingleEventOfType(.Value, withBlock: { (snap) in
        
        var validActivityCounter = 0
        // If there are no activities for the bar there is no reason to see if the activities are for today
        if snap.childrenCount != 0 {
            // Look at every activity with the barId we are looking at
            for act in snap.children {
                let act = act as! FIRDataSnapshot
                if !(act.value is NSNull),let barAct = act.value as? [String : AnyObject] {
                    let userId = Context(id: act.key)
                    let activity = Mapper<BarActivity2>(context: userId).map(barAct)
                    // If the bar activity is for today then increment a counter that will be used to determine top bars
                    if seeIfShouldDisplayBarActivity(activity!) {
                        validActivityCounter += 1
                    }
                }
            }
        }
        handler(numOfUsers: validActivityCounter)
        }, withCancelBlock: { (error) in
            print(error.description)
    })
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
                        
                        
                        addBarToUser(place.placeID, barName: place.name, userName: userName, handler: { (finsihed) in
                            if finsihed {
                                if !(snap.value is NSNull) {
                                    incrementUsersGoing(snap.ref)
                                } else {
                                    createBarAndIncrementUsersGoing(place.coordinate.latitude, long: place.coordinate.longitude, barName: place.name, barId: place.placeID)
                                }
                                
                                // If the user is going to a different bar and chooses to go to the bar displayed, decreament the old bar by one
                                if let oldRef = oldBarRef {
                                    decreamentUsersGoing(oldRef)
                                    // Toggle friends feed about updated barActivity
                                    currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                                        var friendIds = [String]()
                                        for child in snap.children {
                                            if let friend: FIRDataSnapshot = child as? FIRDataSnapshot {
                                                friendIds.append(friend.value as! String)
                                                rootRef.child("users").child(friend.value as! String).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                                            }
                                        }
                                        
                                        SwiftOverlays.removeAllBlockingOverlays()
                                        }, withCancelBlock: { (error) in
                                            SwiftOverlays.removeAllBlockingOverlays()
                                            print(error.description)
                                    })
                                }

                            }
                        })
                    
                    }, withCancelBlock: { (error) in
                            SwiftOverlays.removeAllBlockingOverlays()
                            print(error.description)
                    })
                }
            }
        } else {
            removeBarFromUsers(oldBarRef!)
        }
    }
    
}

extension NSDate {
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

extension NSDate {
    
    func beginningOfDay() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    func endOfDay() -> NSDate {
        let components = NSDateComponents()
        components.day = 1
        var date = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: self.beginningOfDay(), options: [])!
        date = date.dateByAddingTimeInterval(-1)
        return date
    }
}
