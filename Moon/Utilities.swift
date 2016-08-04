//
//  Utilities.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import GooglePlaces
import SwiftOverlays
import SCLAlertView
import Toucan
import Kingfisher

// Returns the time since the bar activity was first created
func getElaspedTime(fromDate: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.timeStyle = .FullStyle
    dateFormatter.dateStyle = .FullStyle
    let activityDate = dateFormatter.dateFromString(fromDate)
    let elaspedTime = (activityDate?.timeIntervalSinceNow)
    
    // Display correct time. hours or minutes
    if (elaspedTime! * -1) < 60 {
        return "<1m"
    } else if (elaspedTime! * -1) < 3600 {
        return "\(Int(elaspedTime! / (-60)))m"
    } else {
        return "\(Int(elaspedTime! / (-3600)))h"
    }
}


func stringToBarSpecial(name:String) -> BarSpecial {
    switch name {
    case "Beer": return BarSpecial.Beer
    case "Wine": return BarSpecial.Wine
    case "Spirits": return BarSpecial.Spirits
    default: break
    }
    return .Beer
    
}

func stringToDay(day:String) -> Day {
    switch day {
    case "Monday": return Day.Monday
    case "Tuesday": return Day.Tuesday
    case "Wednesday": return Day.Wednesday
    case "Thursday": return Day.Thursday
    case "Friday": return Day.Friday
    case "Saturday": return Day.Saturday
    case "Sunday": return Day.Sunday
    case "Weekdays": return Day.Weekdays
    default: break
    }
    return .Monday
}

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

// Turns a string into an image, returns default image if function cant convert string to image
func stringToUIImage(imageString: String, defaultString: String) -> UIImage? {
    let base64EncodedString = imageString
    let imageData = NSData(base64EncodedString: base64EncodedString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
    if imageData != nil {
        let decodedImage = UIImage(data:imageData!)
        return decodedImage
    } else {
        return UIImage(named: defaultString)
    }
}

// Function used to add a special to a certain bar
func addSpecial(barID: String, special: Special) {
    rootRef.child("bars/\(barID)/specials").childByAutoId().setValue(special.toString())
}

// Give it the name of the picture and it will return a string ready to be stored in firebase
func createStringFromImage(imageName: String) -> String? {
    let imageData = UIImageJPEGRepresentation(UIImage(named: imageName)!,0.1)
    let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    return base64String
}


// MARK: - Google Places Photo Functions

// Google bar photo functions based on place id
func loadFirstPhotoForPlace(placeID: String, imageView: UIImageView, indicator: UIActivityIndicatorView, isSpecialsBarPic: Bool) {
    
    GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) { (photos, error) -> Void in
        if let error = error {
            // TODO: handle the error.
            print("Error: \(error.description)")
        } else {
            if let firstPhoto = photos?.results.first {
                loadImageForMetadata(firstPhoto as! GMSPlacePhotoMetadata, imageView: imageView, indicator: indicator, isSpecialsBarPic: isSpecialsBarPic)
            } else {
                // TODO: default bar picture
                indicator.stopAnimating()
                let defaultPhoto = createStringFromImage("DefaultBarPicture")
                imageView.image = stringToUIImage(defaultPhoto!, defaultString: "")
            }
        }
    }
}

func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, imageView: UIImageView, indicator: UIActivityIndicatorView, isSpecialsBarPic: Bool) {
    GMSPlacesClient.sharedClient()
        .loadPlacePhoto(photoMetadata, constrainedToSize: imageView.bounds.size,
                        scale: imageView.window?.screen.scale ?? 2.0) { (photo, error) -> Void in
                            indicator.stopAnimating()
                            if let error = error {
                                // TODO: handle the error.
                                print("Error: \(error.description)")
                            } else {
                                if isSpecialsBarPic {
                                    imageView.image = resizeImage(photo, toTheSize: CGSize(width: 50, height: 50))
                                } else {
                                    imageView.image = photo
                                }
                                // TODO: handle attributes here
                                //self.attributionTextView.attributedText = photoMetadata.attributions;
                            }
    }
}

func checkIfFriendBy(userID:String, handler: (isFriend:Bool)->()) {
    currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
        print(snap)
        for friend in snap.children {
            let friend = friend as! FIRDataSnapshot
                if userID == friend.value as! String {
                    handler(isFriend: true)
                    return
                }
        }
        handler(isFriend: false)
    }) { (error) in
        print(error)
        handler(isFriend: false)
    }
}

// Creates NSDate and turns it into a weekday Enum
func getCurrentDay() -> Day? {
    let todayDate = NSDate()
    let myCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let myComponents = myCalendar.components(.Weekday, fromDate: todayDate)
    let weekDay = myComponents.weekday
    print(weekDay)
    switch weekDay {
    case 1:
        return Day.Sunday
    case 2:
        return Day.Monday
    case 3:
        return Day.Tuesday
    case 4:
        return Day.Wednesday
    case 5:
        return Day.Thursday
    case 6:
        return Day.Friday
    case 7:
        return Day.Saturday
    default:
        return nil
    }
}

func isValidEmail(testStr:String) -> Bool {
    // println("validate calendar: \(testStr)")
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(testStr)
}


func exchangeCurrentBarActivitesWithCurrentUser(userId: String) {
    currentUser.child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if !(snap.value is NSNull) {
            rootRef.child("users").child(userId).child("barFeed").child(currentUser.key).setValue(true)
        }
    }) { (error) in
        print(error)
    }
    rootRef.child("users").child(userId).child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if !(snap.value is NSNull) {
            currentUser.child("barFeed").child(userId).setValue(true)
        }
    }) { (error) in
        print(error.description)
    }
}

func containSameElements<T: Comparable>(array1: [T], _ array2: [T]) -> Bool {
    guard array1.count == array2.count else {
        return false // No need to sorting if they already have different counts
    }
    
    return array1.sort() == array2.sort()
}

func showAppleAlertViewWithText(text: String, presentingVC: UIViewController) {
    // This function is mostly used to show errors
    let alert = UIAlertController(title: "Error", message: text, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
        
    }))
    presentingVC.presentViewController(alert, animated: true, completion: nil)
}

// Displays an alert message with error as the title
func displayAlertWithMessage(message:String) {
    SCLAlertView().showNotice("Error", subTitle: message)
}

/**
 Finds the download ref for the user's profile picture, and then downloads it if not in the cache. Lastly, the image is rezized and given a white border
 - Parameters:
    - userId: The user's id for the picture that is wanted
    - imageView: The image view that will display the picture
 */
func getProfilePictureForUserId(userId: String, imageView: UIImageView) {
    storageRef.child("profilePictures").child(userId).child("userPic").downloadURLWithCompletion { (url, error) in
        if let error = error {
            print(error.description)
        } else if let url = url {
            KingfisherManager.sharedManager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                if let error = error {
                    print(error.description)
                } else if let image = image {
                    let resizedImage = Toucan(image: image).resize(CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
                    let maskImage = Toucan(image: resizedImage).maskWithEllipse(borderWidth: 1, borderColor: UIColor.whiteColor()).image
                    imageView.image = maskImage
                }
            })
        }
    }
}


func getCityPictureForCityId(cityId: String, imageView: UIImageView, indicator: UIActivityIndicatorView, vc: UIViewController) {
    storageRef.child("cityImages").child(cityId).child("cityPic.png").dataWithMaxSize(2*1024*1024) { (data, error) in
        if let error = error {
            showAppleAlertViewWithText(error.description, presentingVC: vc)
        } else {
            if let data = data {
                let myImage = UIImage(data: data)
                let resizedImage = Toucan(image: myImage!).resize(CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
                indicator.stopAnimating()
                imageView.image = resizedImage
                
            }
        }
    }
}

func checkIfUserIsInFirebase(email: String, vc: UIViewController, handler: (isUser: Bool) -> ()) {
    rootRef.child("users").queryOrderedByChild("email").queryEqualToValue(email).observeSingleEventOfType(.Value, withBlock: { (snap) in
        if !(snap.value is NSNull) {
            handler(isUser: true)
        } else {
            handler(isUser: false)
        }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: vc)
    }
}

func checkForWhiteSpaceInString(string: String) -> Bool {
    let whitespace = NSCharacterSet.whitespaceCharacterSet()
    
    let range = string.rangeOfCharacterFromSet(whitespace)
    
    // Range will be nil if no whitespace is found
    if range != nil {
        return true
    }
    else {
        return false
    }
}

// The username has to not already be in use, be between 5 to 12 chars, and not contain any white spaces
func checkIfValidUsername(string: String, vc: UIViewController, handler: (isValid: Bool) -> ()) {
    if string.characters.count >= 5 && string.characters.count <= 12 && !checkForWhiteSpaceInString(string) {
        checkIfUsernameIsAvailable(string, vc: vc, handler: { (isAvailable) -> Void in
            if isAvailable {
                handler(isValid: true)
            } else {
                handler(isValid: false)
            }
        })
    } else {
        handler(isValid: false)
    }
}

// Looks in firebase for the username and returns true if it is available
func checkIfUsernameIsAvailable(string: String, vc: UIViewController, handler: (isAvailable: Bool) -> ()) {
    rootRef.child("users").queryOrderedByChild("username").queryEqualToValue(string).observeSingleEventOfType(.Value, withBlock: { (snap) in
        if snap.value is NSNull {
            handler(isAvailable: true)
        } else {
            handler(isAvailable: false)
        }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: vc)
            handler(isAvailable: false)
    }
}


func checkProviderForCurrentUser(vc: UIViewController, handler: (type: Provider)->()) {
    currentUser.child("provider").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if !(snap.value is NSNull), let provider = snap.value {
            switch Provider(rawValue: provider as! String)! {
            case Provider.Facebook:
                handler(type: .Facebook)
            case Provider.Google:
                handler(type: .Google)
            case Provider.Firebase:
                handler(type: .Firebase)
            }
        }
    }) { (error) in
        showAppleAlertViewWithText(error.description, presentingVC: vc)
    }
}


func checkIfSameUserGroup(group1: [User], group2: [User]) -> Bool {
    // See if the newly pulled data is different from old data
    var sameUsers = true
    if group1.count != group2.count {
        sameUsers = false
    } else {
        for i in 0..<group1.count {
            if group1[i].userID != group1[i].userID {
                sameUsers = false
            }
        }
    }
    return sameUsers
}

func checkIfSameSpecials(group1: [Special], group2: [Special]) -> Bool {
    // See if the newly pulled data is different from old data
    var sameSpecial = true
    if group1.count != group2.count {
        sameSpecial = false
    } else {
        for i in 0..<group1.count {
            if group1[i].description != group1[i].description {
                sameSpecial = false
            }
        }
    }
    return sameSpecial
}

//resizes image to fit in table view
func resizeImage(image:UIImage, toTheSize size:CGSize)->UIImage{
    
    let scale = CGFloat(max(size.width/image.size.width,
        size.height/image.size.height))
    let width:CGFloat  = image.size.width * scale
    let height:CGFloat = image.size.height * scale;
    
    let rr:CGRect = CGRectMake( 0, 0, width, height);
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    image.drawInRect(rr)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    return newImage
}

func updateBio() {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let newInfo = alertView.addTextField("New Bio")
    newInfo.autocapitalizationType = .None
    alertView.addButton("Save", action: {
        currentUser.updateChildValues(["bio": newInfo.text!])
    })
    alertView.showNotice("Update Bio", subTitle: "People can see your bio when viewing your profile")
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
func addBarToUser(barId: String, barName: String, userName: String) {
    
    let activitiesRef = rootRef.child("barActivities")
    
    // Get current time
    let date = NSDate()
    let dateFormatter = NSDateFormatter()
    dateFormatter.timeStyle = .FullStyle
    dateFormatter.dateStyle = .FullStyle
    let currentTime = dateFormatter.stringFromDate(date)
    print(currentTime)
    
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






