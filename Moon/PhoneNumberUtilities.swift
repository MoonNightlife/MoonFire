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

func promptForPhoneNumber() {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let newInfo = alertView.addTextField("New Phone Number")
    alertView.addButton("Send SMS", action: {
        verifyPhoneNumber(newInfo.text!, handler: { (didVerify) in
            currentUser.updateChildValues(["phoneNumber": newInfo.text!])
            rootRef.child("phoneNumbers").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(newInfo.text!)
        })
    })
    alertView.showNotice("Update Phone Number", subTitle: "Your phone number is used to help your friends find you. We do not share your number phone number with other users. Upon entering your number you will be asked to verify by a 4 digit pin.")
}

func verifyPhoneNumber(phoneNumber: String, handler: (didVerify: Bool)->()) {
    sendVerification(phoneNumber) { (didSend, verification) in
        if didSend {
            promptForVerificationCode(verification, handler: { (rightCodeEntered) in
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

func promptForVerificationCode(verification: SINVerificationProtocol, handler: (rightCodeEntered: Bool)->()) {
    let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
    let codeTextField = alertView.addTextField("Code")
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
                    promptForVerificationCode(verification, handler: { (rightCodeEntered) in
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