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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLabelsWithPlace()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // This sees if we already has the bar in our records and if so displays the updated variables
        rootRef.childByAppendingPath("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                let usersGoing = String(bar.value["usersGoing"] as! Int)
                self.usersGoing.text = usersGoing
                let usersThere = String(bar.value["usersGoing"] as! Int)
                self.usersThere.text = usersThere
            }
            }) { (error) in
                print(error.description)
        }
        
        // This looks at the users profile and sees if he or she is attending the bar and then updating the button
        currentUser.childByAppendingPath("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                if(bar.key == self.barPlace.placeID) {
                    self.attendanceButton.titleLabel?.text = "Going"
                } else {
                    self.attendanceButton.titleLabel?.text = "Not Going"
                }
            }
            }) { (error) in
                print(error.description)
        }
    }
    
    func setUpLabelsWithPlace() {
        name.text = barPlace.name
        address.text = barPlace.formattedAddress
        id.text = barPlace.placeID
        phoneNumber.text = barPlace.phoneNumber
        rating.text = "\(barPlace.rating)"
        priceLevel.text = "\(barPlace.priceLevel.rawValue)"
        website.text = barPlace.website!.absoluteString
    }
    
    @IBAction func ChangeAttendanceStatus() {
        if !isGoing {
            // If there is already a bar created updated the number of users going and then assign the bar to the user
            if let barRef = self.barRef {
                barRef.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
                    var value = currentData.value as? Int
                    if (value == nil) {
                        value = 0
                    }
                    currentData.value = value! + 1
                    return FTransactionResult.successWithValue(currentData)
                })
            
            } else {
                // This is where bars are created in firebase, add more moon data here
                barRef = rootRef.childByAppendingPath("bars").childByAppendingPath(barPlace.placeID)
                barRef!.childByAppendingPath("usersGoing").runTransactionBlock({ (currentData) -> FTransactionResult! in
                    var value = currentData.value as? Int
                    if (value == nil) {
                        value = 0
                    }
                    currentData.value = value! + 1
                    return FTransactionResult.successWithValue(currentData)
                })
                barRef!.childByAppendingPath("usersThere").runTransactionBlock({ (currentData) -> FTransactionResult! in
                    var value = currentData.value as? Int
                    if (value == nil) {
                        value = 0
                    }
                    return FTransactionResult.successWithValue(currentData)
                })

            }
            // Add bar to user profile
            currentUser.childByAppendingPath("bars").childByAppendingPath(barPlace.placeID).setValue(1)
        } else {
            
        }
        

    }

}
