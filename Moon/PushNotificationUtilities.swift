//
//  PushNotificationUtilities.swift
//  Moon
//
//  Created by Gabriel I Leyva Merino on 9/12/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Batch
import Firebase

func sendPush(sandBox: Bool, badgeNum: NSInteger, groupId: String, title: String, body: String, customIds:[String], deviceToken: String){
    
    
   //Batch Set Up
   // You can find these keys on your Dashboard
   // let devDeviceToken = deviceToken
    if let pushClient = BatchClientPush(apiKey: "57D6284DBEF27DB3848C82253CEA43", restKey: "d3c050e095474b005588ed3e857baf94") {
        pushClient.sandbox = sandBox
        pushClient.customPayload = ["aps": ["badge": badgeNum]]
        pushClient.groupId = "tests"
        pushClient.message.title = title
        pushClient.message.body = body
        pushClient.recipients.customIds = customIds
        //pushClient.recipients.tokens.append(devDeviceToken)
        
        pushClient.send { (response, error) in
            if let error = error {
                print("Something happened while sending the push: \(response) \(error.localizedDescription)")
            } else {
                print("Push sent \(response)")
            }
        }
        
    } else {
        print("Error while initializing BatchClientPush")
    }
    
}

/**
 This function takes in a string which repersents a user id. It then looks at the users settings to see if the user would like to receive notifications for like.
 - Author: Evan Noble
 - Parameters:
    - userId: the user id we are checking the settings for
    - handler: a closure that returns true if notification is allowed
 */
func seeIfUserAllowsBarActivityLikeNotifications(userId: String, handler: (allowed: Bool)->()) {
    rootRef.child("users").child(userId).child("notificationSettings").child("peopleLikingStatus").observeSingleEventOfType(.Value, withBlock: { (snap) in
        if (snap.value is NSNull) {
            handler(allowed: true)
        } else {
            if let setting = snap.value {
                if setting as! Bool {
                    handler(allowed: true)
                }
            }
        }
        handler(allowed: false)
        }) { (error) in
            print(error)
            handler(allowed: false)
    }
}

/**
 This fucntion takes in an array for friend ids and checks each users settings to see if they all notifcations to be sent to them in one of their friends goes to a new bar. If the user hasn't open their settings to turn off the notifications then they are sent by default. It returns the filered array of user ids.
 - Author: Evan Noble
 - Parameters:
    - allFriends: the array of all the users friends
    - handler: a closure used to return the new filtered array described above
 */
func filterArrayForPeopleThatAcceptFriendsGoingOutNotifications(allFriends: [String], handler: (filteredFriends: [String]) -> ()) {
    var filteredArray = [String]()
    var count = 0
    for friend in allFriends {
        rootRef.child("users").child(friend).child("notificationSettings").child("friendsGoingOut").observeSingleEventOfType(.Value, withBlock: { (snap) in
            // This forces the notifcations to be on by default since this feature was released after the original launch, so not all accounts have this setting. So if they don't find this setting under the user profile we will send the notification
            count += 1
            if (snap.value is NSNull) {
                filteredArray.append(friend)
            } else {
                if let setting = snap.value {
                    if setting as! Bool {
                        filteredArray.append(friend)
                    }
                }
            }
            // Wait for the last user setting to be checked before returning the array of userIds to the closure
            if count == allFriends.count {
                handler(filteredFriends: filteredArray)
            }
            }, withCancelBlock: { (error) in
                print(error)
        })
    }
}

