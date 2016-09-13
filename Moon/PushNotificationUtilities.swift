//
//  PushNotificationUtilities.swift
//  Moon
//
//  Created by Gabriel I Leyva Merino on 9/12/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Batch

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