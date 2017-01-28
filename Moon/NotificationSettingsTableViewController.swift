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
import RxSwift

class NotificationSettingsTableViewController: UITableViewController {
    
    private let pushNotificationSettingsService: PushNotificationSettingsService = FirebasePushNotificationSettingsService()
    
    private let disposeBag = DisposeBag()

    //MARK: - Outlets
    @IBOutlet weak var friendsGoingOut: UISwitch!
    @IBOutlet weak var peopleLikingStatus: UISwitch!
    
    //MARK: - Actions
    @IBAction func friendsGoingOut(sender: UISwitch) {
        pushNotificationSettingsService.updateFriendsGoingOutNotificaticationSetting(sender.on)
            .subscribeNext { (response) in
                switch response {
                case .Success:
                    print("saved")
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func peopleLikingStatus(sender: UISwitch) {
        pushNotificationSettingsService.updatePeopleLikingStatusNotificationSetting(sender.on)
            .subscribeNext { (response) in
                switch response {
                case .Success:
                    print("saved")
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Push Notifications"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if checkIfNotificationsAreAllowed() {
            getUserNotificationInformation()
        } else {
            // Should force other notifcations off and disabled when adding new ones in the future
            friendsGoingOut.on = false
            friendsGoingOut.enabled = false
            peopleLikingStatus.on = false
            peopleLikingStatus.enabled = false
            let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
            alertView.showNotice("Push Notifications Off", subTitle: "Push Notifications are currently turned off. Go to your phone settings to turn them on for this app.")
        }
    }
    
    //MARK: - Helper functions for view
    private func getUserNotificationInformation() {
        
        pushNotificationSettingsService.getNotificationSettingsForSignedInUser()
            .subscribeNext { (results) in
                switch results {
                case .Success(let settings):
                    self.assignValuesToViewFrom(NotifcationSettings: settings)
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    private func assignValuesToViewFrom(NotifcationSettings settings: NotificationSettings) {
        // If the user doesnt have anything saved for a certain notification setting, then the default is true (on)
        self.friendsGoingOut.on = settings.friendsGoingOut ?? true
        self.peopleLikingStatus.on = settings.peopleLikingStatus ?? true
    }
    
    private func checkIfNotificationsAreAllowed() -> Bool {
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(.Alert) {
                // Have alert permission
                return true
            }
        }
        return false
    }

}
