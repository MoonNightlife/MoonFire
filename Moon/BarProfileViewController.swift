//
//  BarProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import GeoFire
import MapKit
import CoreLocation

class BarProfileViewController: UIViewController {
    
    var barPlace:GMSPlace!
    var barRef: Firebase?
    var isGoing: Bool = false
    var oldBarRef: Firebase?
    
    // MARK: - Outlets

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var priceLevel: UILabel!
    @IBOutlet weak var website: UILabel!
    @IBOutlet weak var usersGoing: UILabel!
    @IBOutlet weak var usersThere: UILabel!
    @IBOutlet weak var attendanceButton: UIButton!
    @IBOutlet weak var barImage: UIImageView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLabelsWithPlace()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // This sees if we already have the bar in our records and if so displays the updated variables
        rootRef.childByAppendingPath("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                if !(bar is NSNull) {
                    print(bar)
                    self.barRef = bar.ref
                    let usersGoing = String(bar.value["usersGoing"] as! Int)
                    self.usersGoing.text = usersGoing
                    let usersThere = String(bar.value["usersThere"] as! Int)
                    self.usersThere.text = usersThere
                }
            }
            }) { (error) in
                print(error.description)
        }
        
        // This looks at the users profile and sees if he or she is attending the bar and then updating the button
        currentUser.childByAppendingPath("currentBar").observeEventType(.Value, withBlock: { (snap) in
            if(!(snap.value is NSNull)) {
            if(snap.value as! String == self.barPlace.placeID) {
                self.isGoing = true
                self.attendanceButton.titleLabel?.text = "Going"
            } else {
                self.isGoing = false
                self.attendanceButton.titleLabel?.text = "Not Going"
                // If there is another bar that the user was going to, store address to decreament if need be
                self.oldBarRef = rootRef.childByAppendingPath("bars").childByAppendingPath(snap.value as! String)
                }
            } else {
                self.isGoing = false
                self.attendanceButton.titleLabel?.text = "Not Going"
            }
            }) { (error) in
                print(error.description)
        }
    }
    
    // Helper function that updates the view with the bar information
    func setUpLabelsWithPlace() {
        
        name.text = barPlace.name
        address.text = barPlace.formattedAddress
        id.text = barPlace.placeID
        phoneNumber.text = barPlace.phoneNumber
        rating.text = "\(barPlace.rating)"
        priceLevel.text = "\(barPlace.priceLevel.rawValue)"
        if let site = barPlace.website {
            website.text = site.absoluteString
        } else {
            website.text = "None"
        }
        
        // Get bar photos
        loadFirstPhotoForPlace(barPlace.placeID)
    }
    
    // Action that changes the ammount of users going to bar as well as changes the users current bar
    @IBAction func ChangeAttendanceStatus() {
        if !isGoing {
            // If there is already a bar created updated the number of users going
            if let barRef = self.barRef {
                incrementUsersGoing(barRef)
            } else {
                createBarAndIncrementUsersGoing()
            }
            addBarToUser()
            // If the user is going to a different bar and chooses to go to the bar displayed, decreament the old bar by one
            if let oldRef = oldBarRef {
                decreamentUsersGoing(oldRef)
                // Toggle friends feed about updated barActivity
                currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    for child in snap.children {
                        if let friend: FDataSnapshot = child as? FDataSnapshot {
                            rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                        }
                    }
                    }, withCancelBlock: { (error) in
                        print(error.description)
                })
                oldBarRef = nil
            }
        } else {
            decreamentUsersGoing(self.barRef!)
            removeBarFromUsers()
        }
    }
    
    // Adds bar activity to firebase, also addeds bar ref to user as well as adding the reference to the bar activity to friends barFeeds
    func addBarToUser() {
        
        let activitiesRef = rootRef.childByAppendingPath("barActivities")
        
        // Get current time
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .FullStyle
        dateFormatter.dateStyle = .FullStyle
        let currentTime = dateFormatter.stringFromDate(date)
        print(currentTime)
        
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            // Save activity under barActivities
            let activity = ["barID": self.barPlace.placeID, "barName": self.barPlace.name, "time": currentTime, "userName": snap.value["name"] as! String]
            activitiesRef.childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(activity)
            
            // Save reference for barActivity under current user
            currentUser.childByAppendingPath("currentBar").setValue(self.barPlace.placeID)
            
            // Save reference for barActivity under each friends feed
            currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                for child in snap.children {
                    if let friend: FDataSnapshot = child as? FDataSnapshot {
                    rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                    }
                }
                }, withCancelBlock: { (error) in
                    print(error.description)
            })
            
            }) { (error) in
                print(error.description)
        }
        
        
    }
    
    // Removes all exsitance of the bar activity
    func removeBarFromUsers() {
        
        // Remove bar reference from barActivities
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
                rootRef.childByAppendingPath("barActivities").childByAppendingPath(snap.key).removeValue()
            }) { (error) in
                print(error.description)
        }
        
        
        // Remove bar reference from current user
        currentUser.childByAppendingPath("currentBar").removeValue()
        
        // Remove bar activity from friend's feed
        currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for child in snap.children {
                if let friend: FDataSnapshot = child as? FDataSnapshot {
                    rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
                }
            }
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    // Decreament users going to a certain bar
    func decreamentUsersGoing(barRef: Firebase) {
        barRef.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! - 1
            return FTransactionResult.successWithValue(currentData)
        })
    }
    
    // Increases users going to a certain bar
    func incrementUsersGoing(barRef: Firebase) {
        barRef.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! + 1
            return FTransactionResult.successWithValue(currentData)
        })
    }

    // Creates a new bar and sets init information
    func createBarAndIncrementUsersGoing() {
        // Find the radius of bar for region monitoring
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: barPlace.coordinate.latitude, longitude: barPlace.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if placemarks?.count > 1 {
                print("too many placemarks for convertion")
            } else if error == nil {
                let placemark = (placemarks![0] as CLPlacemark)
                let circularRegion = placemark.region as? CLCircularRegion
                let radius = circularRegion?.radius
                // This is where bars are created in firebase, add more moon data here
                self.barRef = rootRef.childByAppendingPath("bars").childByAppendingPath(self.barPlace.placeID)
                let initBarData = ["usersGoing" : 1, "usersThere" : 0, "radius" : radius!, "barName" : self.barPlace.name]
                self.barRef?.setValue(initBarData)
            }  else {
                print(error?.description)
            }
                
            // This creates a geoFire location
            geoFire.setLocation(CLLocation(latitude: self.barPlace.coordinate.latitude, longitude: self.barPlace.coordinate.longitude), forKey: self.barPlace.placeID) { (error) in
                if error != nil {
                    print(error.description)
                }
            }
        }
        
    }
    
    // Google bar photo functions based on place id
    func loadFirstPhotoForPlace(placeID: String) {
        GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.description)")
            } else {
                if let firstPhoto = photos?.results[1] {
                    self.loadImageForMetadata(firstPhoto)
                }
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.sharedClient()
            .loadPlacePhoto(photoMetadata, constrainedToSize: barImage.bounds.size,
                            scale: self.barImage.window!.screen.scale) { (photo, error) -> Void in
                                if let error = error {
                                    // TODO: handle the error.
                                    print("Error: \(error.description)")
                                } else {
                                    self.barImage.image = photo;
                                    // TODO: handle attributes here
                                    //self.attributionTextView.attributedText = photoMetadata.attributions;
                                }
        }
    }
}
