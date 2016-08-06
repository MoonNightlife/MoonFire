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

/**
 This function turns a date into an elasped time string.
 - Author: Evan Noble
 - Parameters:
    - fromDate: NSDate to be converted to string
 */
func getElaspedTimefromDate(fromDate: NSDate) -> String {

    let elaspedTime = fromDate.timeIntervalSinceNow
    
    // Display correct time. Hours, Minutes
    if (elaspedTime * -1) < 60 {
        return "<1m"
    } else if (elaspedTime * -1) < 3600 {
        return "\(Int(elaspedTime / (-60)))m"
    } else {
        return "\(Int(elaspedTime / (-3600)))h"
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

/**
 This function gets the current weekday
 - Author: Evan Noble
 - Returns: the current weekday
 */
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





func updateBio() {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let newInfo = alertView.addTextField("New Bio")
    newInfo.autocapitalizationType = .None
    alertView.addButton("Save", action: {
        currentUser.updateChildValues(["bio": newInfo.text!])
    })
    alertView.showNotice("Update Bio", subTitle: "People can see your bio when viewing your profile")
}

func genderSymbolFromGender(gender: Gender?) -> String? {
    // Use the correct gender symbol
    let male = "\u{2642}"
    let female = "\u{2640}"

    if gender == .Male {
        return male
    } else if gender == .Female {
        return female
    } else {
        return nil
    }
}

// Start updating location if allowed, if not prompts user to settings
func checkAuthStatus(vc: UIViewController) {
    switch CLLocationManager.authorizationStatus() {
    case .AuthorizedWhenInUse:
        LocationService.sharedInstance.startUpdatingLocation()
    case .NotDetermined:
        LocationService.sharedInstance.locationManager?.requestWhenInUseAuthorization()
    case .Restricted, .Denied, .AuthorizedAlways:
        let alertController = UIAlertController(
            title: "Location Access Disabled",
            message: "In order to be see the most popular bars near you, please open this app's settings and set location access to 'When In Use'.",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
}








