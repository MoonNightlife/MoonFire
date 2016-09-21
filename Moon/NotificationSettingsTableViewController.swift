//
//  NotificationSettingsTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 9/19/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SwiftOverlays
import SCLAlertView

class NotificationSettingsTableViewController: UITableViewController {

    //MARK: - Outlets
    @IBOutlet weak var friendsGoingOut: UISwitch!
    
    //MARK: - Actions
    @IBAction func friendsGoingOut(sender: UISwitch) {
        currentUser.child("notificationSettings").child("friendsGoingOut").setValue(sender.on)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Push Notifications"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if checkIfNotificationsAreAllowed() {
            getUserNotificationInformation()
        } else {
            friendsGoingOut.on = false
            friendsGoingOut.enabled = false
            let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
            alertView.showNotice("Push Notifications Off", subTitle: "Push Notifications are currently turned off. Go to your phone settings to turn them on for this app.")
        }
    }
    
    //MARK: - Helper functions for view
    func getUserNotificationInformation() {
        showWaitOverlay()
        currentUser.child("notificationSettings").observeEventType(.Value, withBlock: { (snap) in
            // This forces the notifcations to be on by default since this feature was released after the original launch, so not all accounts have this setting
            if (snap.value is NSNull) {
                // Should force other notifcations on when they are added
                self.friendsGoingOut.on = true
            }
            for notificationSetting in snap.children {
                let setting = notificationSetting as! FIRDataSnapshot
                if setting.key == "friendsGoingOut" {
                    self.friendsGoingOut.on = setting.value as! Bool
                }
            }
            self.removeAllOverlays()
            }) { (error) in
                self.removeAllOverlays()
                print(error)
        }
    }
    
    func checkIfNotificationsAreAllowed() -> Bool {
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(.Alert) {
                // Have alert permission
                return true
            }
        }
        return false
    }
    
    func promptUserToRegisterPushNotifications() {

    }

}
