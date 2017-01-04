//
//  BatchService.swift
//  Moon
//
//  Created by Evan Noble on 12/6/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Batch

protocol PushNotificationService {
    func addUserToNotificationProvider(uid: String)
    func sendPushNotifcationWith(Options options: PushOptions)
}

enum BatchGroupId: String {
    case FriendsGoingOut = "Friends Going Out"
}

struct PushOptions {
    
    var sandBox: Bool, badgeNum: NSInteger, groupId: String, title: String, body: String, customIds:[String], deviceToken: String
    
    init(sandBox: Bool = false, badgeNum: NSInteger = 1, groupId: String, title: String, body: String, customIds:[String], deviceToken: String = "nil") {
        self.sandBox = sandBox
        self.badgeNum = badgeNum
        self.groupId = groupId
        self.title = title
        self.body = body
        self.customIds = customIds
        self.deviceToken = deviceToken
    }
}

struct BatchService: PushNotificationService {
    
    private let apiKey = "57D6284DBEF27DB3848C82253CEA43"
    private let restKey = "d3c050e095474b005588ed3e857baf94"
    
    func addUserToNotificationProvider(uid: String) {
        let editor = BatchUser.editor()
        editor.setIdentifier(uid)
        editor.save() // Do not forget to save the changes!
    }
    
    func sendPushNotifcationWith(Options options: PushOptions) {
    
        //Batch Set Up
        // You can find these keys on your Dashboard
        // let devDeviceToken = deviceToken
        if let pushClient = BatchClientPush(apiKey: apiKey, restKey: restKey) {
            pushClient.sandbox = options.sandBox
            pushClient.customPayload = ["aps": ["badge": options.badgeNum]]
            pushClient.groupId = options.groupId
            pushClient.message.title = options.title
            pushClient.message.body = options.body
            pushClient.recipients.customIds = options.customIds
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

}