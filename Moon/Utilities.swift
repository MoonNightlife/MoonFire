//
//  Utilities.swift
//  Moon
//
//  Created by Evan Noble on 6/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import GoogleMaps
import SwiftOverlays


// Returns the time since the bar activity was first created
func getElaspedTime(fromDate: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.timeStyle = .FullStyle
    dateFormatter.dateStyle = .FullStyle
    let activityDate = dateFormatter.dateFromString(fromDate)
    let elaspedTime = (activityDate?.timeIntervalSinceNow)
    
    // Display correct time. hours or minutes
    if (elaspedTime! * -1) < 60 {
        return "<1m ago"
    } else if (elaspedTime! * -1) < 3600 {
        return "\(Int(elaspedTime! / (-60)))m ago"
    } else {
        return "\(Int(elaspedTime! / (-3600)))h ago"
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
func loadFirstPhotoForPlace(placeID: String, imageViewSize: CGSize, imageViewScale: CGFloat, handler: (image: UIImage) -> ()) {
    
    GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) { (photos, error) -> Void in
        if let error = error {
            // TODO: handle the error.
            print("Error: \(error.description)")
        } else {
            if let firstPhoto = photos?.results.first {
                loadImageForMetadata(firstPhoto, imageViewSize: imageViewSize, imageViewScale: imageViewScale, handler: { (image) in
                    handler(image: image)
                })
            } else {
                // TODO: default bar picture
                let defaultPhoto = createStringFromImage("DefaultBarPicture")
                handler(image: stringToUIImage(defaultPhoto!, defaultString: "")!)
            }
        }
    }
}

func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, imageViewSize: CGSize, imageViewScale: CGFloat, handler: (image: UIImage) -> ()) {
    GMSPlacesClient.sharedClient()
        .loadPlacePhoto(photoMetadata, constrainedToSize: imageViewSize,
                        scale: imageViewScale ?? 2.0) { (photo, error) -> Void in
                            
                            if let error = error {
                                // TODO: handle the error.
                                print("Error: \(error.description)")
                            } else {
                                handler(image: photo!)
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
        if snap.value != nil {
            rootRef.child("users").child(userId).child("barFeed").child(currentUser.key).setValue(true)
        }
    }) { (error) in
        print(error)
    }
    rootRef.child("users").child(userId).child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if snap.value != nil {
            currentUser.child("barFeed").child(userId).setValue(true)
        }
    }) { (error) in
        print(error.description)
    }
}









