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
    alertView.addButton("Save", action: {
        verifyPhoneNumber(newInfo.text!, handler: { (didVerify) in
            currentUser.updateChildValues(["phoneNumber": newInfo.text!])
            rootRef.child("phoneNumbers").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(newInfo.text!)
        })
    })
    
    alertView.showNotice("Update Phone Number", subTitle: "Your phone number is used to help your friends find you.")
}

func verifyPhoneNumber(phoneNumber: String, handler: (didVerify: Bool)->()) {
    sendVerification(phoneNumber) { (didSend, verification) in
        if didSend {
            promptForVerificationCode(verification, handler: { (rightCodeEntered) in
                if rightCodeEntered {
                    handler(didVerify: true)
                } else {
                    // prompt user again
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
        print(verification)
        // retain the verification instance
        verification.initiateWithCompletionHandler({(success: Bool, error: NSError?) -> Void in
            if success {
                handler(didSend: true, verification: verification)
            } else {
                if let error = error {
                    print(error)
                }
            }
        })
    } catch {
        print("Phone number not returned when formmating")
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
                // Ask user to re-attempt verification
            }
        })
    }
    alertView.showNotice("Enter Verification Code", subTitle: "You should recieve a text shortly")
}