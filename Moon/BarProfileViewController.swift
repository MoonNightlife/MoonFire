//
//  BarProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class BarProfileViewController: UIViewController {
    
    var barPlace:GMSPlace!
    var barRef: Firebase?
    var isGoing: Bool = false
    
    // MARK: - Outlets

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var priceLevel: UILabel!
    @IBOutlet weak var website: UILabel!
    @IBOutlet weak var usersGoing: UILabel!
    @IBOutlet weak var usersThere: UILabel!
    @IBOutlet weak var attendanceButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLabelsWithPlace()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // This sees if we already have the bar in our records and if so displays the updated variables
        rootRef.childByAppendingPath("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                if !(bar is NSNull) {
                    print(bar)
                    self.barRef = bar.ref
                    let usersGoing = String(bar.value["usersGoing"] as! Int)
                    self.usersGoing.text = usersGoing
                    let usersThere = String(bar.value["usersThere"] as! Int)
                    self.usersThere.text = usersThere
                }
            }
            }) { (error) in
                print(error.description)
        }
        
        // This looks at the users profile and sees if he or she is attending the bar and then updating the button
        currentUser.childByAppendingPath("currentBar").observeEventType(.Value, withBlock: { (snap) in
            if(!(snap.value is NSNull)) {
            if(snap.value as! String == self.barPlace.placeID) {
                    self.isGoing = true
                    self.attendanceButton.titleLabel?.text = "Going"
                } else {
                    self.isGoing = false
                    self.attendanceButton.titleLabel?.text = "Not Going"
                }
            }
            }) { (error) in
                print(error.description)
        }
    }
    
    // Helper function that updates the view with the bar information
    func setUpLabelsWithPlace() {
        
        name.text = barPlace.name
        address.text = barPlace.formattedAddress
        id.text = barPlace.placeID
        phoneNumber.text = barPlace.phoneNumber
        rating.text = "\(barPlace.rating)"
        priceLevel.text = "\(barPlace.priceLevel.rawValue)"
        if let site = barPlace.website {
            website.text = site.absoluteString
        } else {
            website.text = "None"
        }
    }
    
    // Action that changes the ammount of users going to bar as well as changes the users current bar
    @IBAction func ChangeAttendanceStatus() {
        if !isGoing {
            // If there is already a bar created updated the number of users going
            if let barRef = self.barRef {
                incrementUsersGoing(barRef)
            } else {
                createBarAndIncrementUsersGoing()
            }
            addBarToUser()
        } else {
            removeBarFromUser()
            decreamentUsersGoing(self.barRef!)
        }
    }
    
    // Adds bar to user
    func addBarToUser() {
        currentUser.childByAppendingPath("currentBar").setValue(barPlace.placeID)
    }
    
    // Remove bar from user
    func removeBarFromUser() {
        currentUser.childByAppendingPath("currentBar").setValue("0")
    }
    
    // Decreament users going to a certain bar
    func decreamentUsersGoing(barRef: Firebase) {
        barRef.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! - 1
            return FTransactionResult.successWithValue(currentData)
        })
    }
    
    // Increases users going to a certain bar
    func incrementUsersGoing(barRef: Firebase) {
        barRef.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! + 1
            return FTransactionResult.successWithValue(currentData)
        })
    }

    // Creates a new bar and sets init information
    func createBarAndIncrementUsersGoing() {
        // This is where bars are created in firebase, add more moon data here
        barRef = rootRef.childByAppendingPath("bars").childByAppendingPath(barPlace.placeID)
        let initBarData = ["usersGoing" : 1, "usersThere" : 0]
        barRef?.setValue(initBarData)
    }
}
