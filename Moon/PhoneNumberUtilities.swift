//
//  PhoneNumberUtilities.swift
//  Moon
//
//  Created by Evan Noble on 9/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView
import Firebase
import SinchVerification

func promptForPhoneNumber(delegate: UITextFieldDelegate) {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let newInfo = alertView.addTextField("New Phone Number")
    newInfo.tag = 69
    newInfo.delegate = delegate
    newInfo.keyboardType = .PhonePad
    alertView.addButton("Send SMS", action: {
        verifyPhoneNumber(delegate, phoneNumber: newInfo.text!, handler: { (didVerify) in
            if didVerify {
                currentUser.updateChildValues(["phoneNumber": newInfo.text!])
                rootRef.child("phoneNumbers").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(newInfo.text!)
            }
        })
    })
    alertView.showNotice("Update Phone Number", subTitle: "Your phone number is used to help your friends find you. We do not share your number phone number with other users. Upon entering your number you will be asked to verify by a 4 digit pin.")
}

func verifyPhoneNumber(delegate: UITextFieldDelegate, phoneNumber: String, handler: (didVerify: Bool)->()) {
    sendVerification(phoneNumber) { (didSend, verification) in
        if didSend {
            promptForVerificationCode(delegate, verification: verification, handler: { (rightCodeEntered) in
                if rightCodeEntered {
                    handler(didVerify: true)
                }
            })
        }
    }
}

func sendVerification(phoneNumber: String, handler: (didSend: Bool, verification: SINVerificationProtocol)->()) {
    // The output below is limited by 1 KB.
    // Please Sign Up (Free!) to remove this limitation.
    
    // Get user's current region by carrier info
    let defaultRegion = SINDeviceRegion.currentCountryCode()
    do {
        let phoneNumber = try SINPhoneNumberUtil().parse(phoneNumber, defaultRegion: defaultRegion)
        let phoneNumberInE164 = SINPhoneNumberUtil().formatNumber(phoneNumber, format: .E164)
        let verification = SINVerification.SMSVerificationWithApplicationKey("1c4d1e22-0863-479a-8d15-4ecc6d2f6807", phoneNumber: phoneNumberInE164)
        // retain the verification instance
        verification.initiateWithCompletionHandler({(success: Bool, error: NSError?) -> Void in
            if success {
                print(phoneNumber)
                handler(didSend: true, verification: verification)
            } else {
                if let error = error {
                    print(error)
                }
                let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
                alertView.showNotice("Please Try Again", subTitle: "Make sure you are entering a valid phone number.")
            }
        })
    } catch {
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        alertView.showNotice("Please Try Again", subTitle: "Make sure you are entering a valid phone number.")
    }

}

func promptForVerificationCode(delegate: UITextFieldDelegate, verification: SINVerificationProtocol, handler: (rightCodeEntered: Bool)->()) {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let codeTextField = alertView.addTextField("Code")
    codeTextField.tag = 169
    codeTextField.delegate = delegate
    codeTextField.keyboardType = .NumberPad
    alertView.addButton("Verify") { 
        // User pressed a "Done" button after entering the code from the SMS.
        let code = codeTextField.text!
        verification.verifyCode(code, completionHandler: {(success: Bool, error: NSError?) -> Void in
            if success {
                handler(rightCodeEntered: true)
                print("verified")
            }
            else {
                let alertViewError = SCLAlertView(appearance: K.Apperances.NormalApperance)
                alertViewError.addButton("Try Again", action: { 
                    promptForVerificationCode(delegate, verification: verification, handler: { (rightCodeEntered) in
                        if rightCodeEntered {
                            handler(rightCodeEntered: true)
                        }
                    })
                })
                alertViewError.showNotice("Error", subTitle: "Please make sure you enter the correct code.")
            }
        })
    }
    alertView.showNotice("Enter Verification Code", subTitle: "You should recieve a text shortly")
}

func shouldPinNumberTextFieldChange(textField: UITextField, range: NSRange, string: String) -> Bool {
    let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
    if (newString.characters.count < textField.text?.characters.count && newString.characters.count >= 1) {
        return true                                                         // return true for backspace to work
    }
    if textField.text?.characters.count > 3 {
        return false
    }
    return true
}

func shouldPhoneNumberTextChangeHelperMethod(textField: UITextField, range: NSRange, string: String) -> Bool {
    let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
    
    if (newString.characters.count < textField.text?.characters.count && newString.characters.count >= 1) {
        return true                                                         // return true for backspace to work
    } else if (newString.characters.count < 1) {
        return false;                        // deleting "+" makes no sence
    }
    if (newString.characters.count > 17 ) {
        return false;
    }
    
    let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
    
    let decimalString = components.joinWithSeparator("") as NSString
    let length = decimalString.length
    
    var index = 0
    let formattedString = NSMutableString()
    formattedString.appendString("+")
    
    if (length >= 1) {
        let countryCode = decimalString.substringWithRange(NSMakeRange(0, 1))
        formattedString.appendString(countryCode)
        index += 1
    }
    
    if (length > 1) {
        var rangeLength = 3
        if (length < 4) {
            rangeLength = length - 1
        }
        let operatorCode = decimalString.substringWithRange(NSMakeRange(1, rangeLength))
        formattedString.appendFormat(" (%@) ", operatorCode)
        index += operatorCode.characters.count
    }
    
    if (length > 4) {
        var rangeLength = 3
        if (length < 7) {
            rangeLength = length - 4
        }
        let prefix = decimalString.substringWithRange(NSMakeRange(4, rangeLength))
        formattedString.appendFormat("%@-", prefix)
        index += prefix.characters.count
    }
    
    if (index < length) {
        let remainder = decimalString.substringFromIndex(index)
        formattedString.appendString(remainder)
    }
    
    textField.text = formattedString as String
    
    if (newString.characters.count == 17) {
        textField.resignFirstResponder()
    }
    
    return false

}


