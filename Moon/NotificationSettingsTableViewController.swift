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

class NotificationSettingsTableViewController: UITableViewController {

    //MARK: - Outlets
    @IBOutlet weak var friendsGoingOut: UISwitch!
    
    //MARK: - Actions
    @IBAction func friendsGoingOut(sender: UISwitch) {
        currentUser.child("notificationSettings").child("friendsGoingOut").setValue(sender.on)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            friendsGoingOut.userInteractionEnabled = false
            //TODO: Prompt user to go to settings and turn on notifications
        }
    }
    
    //MARK: - Helper functions for view
    func getUserNotificationInformation() {
        showWaitOverlay()
        currentUser.child("notificationSettings").observeEventType(.Value, withBlock: { (snap) in
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
