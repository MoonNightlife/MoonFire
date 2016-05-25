//
//  UserProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/21/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SwiftOverlays

class UserProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    var userID: String!
    var isCurrentFriend: Bool = false
    var hasFriendRequest: Bool = false
    var sentFriendRequest: Bool = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var age: UILabel!
    @IBOutlet weak var gender: UILabel!
    @IBOutlet weak var addFriendButton: UIButton!
    
    
    //MARK: - Actions
    
    @IBAction func viewFriends() {
        performSegueWithIdentifier("showFriendsFromSearch", sender: nil)
    }
   
    @IBAction func addFriend() {
        if !sentFriendRequest {
            if !isCurrentFriend {
                if !hasFriendRequest {
                    sendFriendRequest()
                } else {
                    acceptFriendRequest()
                }
            }else {
                unfriendUser()
            }
        } else {
           cancelFriendRequest()
        }
        
    }
    
    func cancelFriendRequest() {
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("friendRequest").childByAppendingPath(self.userID).childByAppendingPath(snap.value["username"] as! String).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }

    
    func reloadFriendButton() {
        if !sentFriendRequest {
            if !isCurrentFriend {
                if !hasFriendRequest {
                    self.addFriendButton.setTitle("Add Friend", forState: .Normal)
                } else {
                    self.addFriendButton.setTitle("Accept", forState: .Normal)
                }
            }else {
                self.addFriendButton.setTitle("Unfriend", forState: .Normal)
            }
        } else {
            self.addFriendButton.setTitle("Cancel Request", forState: .Normal)
        }
        self.removeAllOverlays()
    }
    
    func sendFriendRequest() {
        // Send friend request
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("friendRequest/\(self.userID)").childByAppendingPath(snap.value["username"] as! String).setValue(snap.key)
                self.removeAllOverlays()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func unfriendUser() {
        currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).removeValue()
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("users").childByAppendingPath(self.userID).childByAppendingPath("friends").childByAppendingPath(snap.value["username"] as! String).removeValue()
            self.removeAllOverlays()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func acceptFriendRequest() {
        currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).setValue(self.userID)
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("users/\(self.userID)/friends").childByAppendingPath(snap.value["username"] as! String).setValue(snap.key)
            rootRef.childByAppendingPath("friendRequest").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).childByAppendingPath(self.username.text).removeValue()
            self.removeAllOverlays()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
        
    }
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        //sets a circular profile pic
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true

    }
    
    func getProfileInformation() {
        // Monitor the user that was passed to the controller and update view with their information
        
        rootRef.childByAppendingPath("users").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (userSnap) in
            self.username.text = userSnap.value["username"] as? String
            self.name.text = userSnap.value["name"] as? String
            self.email.text = userSnap.value["email"] as? String
            self.age.text = userSnap.value["age"] as? String
            self.gender.text = userSnap.value["gender"] as? String
            
            let base64EncodedString = userSnap.value["profilePicture"]
            if let imageString = base64EncodedString! {
                let imageData = NSData(base64EncodedString: imageString as! String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                self.profilePicture.image = decodedImage
            }
            
        }) { (error) in
            print(error.description)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        getProfileInformation()
        checkIfUserIsFriend()
        checkForSentFriendRequest()
        checkForFriendRequest()
    }
    
    // Check is user is friend
    func checkIfUserIsFriend() {
        // Check friend status
        currentUser.childByAppendingPath("friends").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
            if snap.value is NSNull {
                self.isCurrentFriend = false
                
            } else {
                self.isCurrentFriend = true
            }
            self.reloadFriendButton()
        }) { (error) in
            print(error.description)
        }
    }
    
    // Check if user is requesting to be your friend
    func checkForFriendRequest() {
     
        rootRef.childByAppendingPath("friendRequest/\(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.hasFriendRequest = true
            } else {
                self.hasFriendRequest = false
            }
            self.reloadFriendButton()
            }, withCancelBlock: { (error
                ) in
                print(error.description)
        })
    }
    
    func checkForSentFriendRequest() {
            rootRef.childByAppendingPath("friendRequest").childByAppendingPath(self.userID).queryOrderedByValue().queryEqualToValue(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.sentFriendRequest = true
                } else {
                    self.sentFriendRequest = false
                }
                self.reloadFriendButton()
                }, withCancelBlock: { (error
                    ) in
                    print(error.description)
            })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFriendsFromSearch" {
            let vc = segue.destinationViewController as! FriendsTableViewController
            vc.currentUser = rootRef.childByAppendingPath("users").childByAppendingPath(userID)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        rootRef.childByAppendingPath(userID).removeAllObservers()
    }

}
