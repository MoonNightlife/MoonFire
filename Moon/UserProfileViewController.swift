//
//  UserProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/21/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    var userID: String!
    var isCurrentFriend: Bool = false {
        willSet {
            if newValue == true {
                addFriendButton.titleLabel?.text = "Unfriend"
            } else {
                addFriendButton.titleLabel?.text = "Add Friend"
            }
        }
    }
    
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
        if !isCurrentFriend {
            currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).setValue(userID)
        } else {
            currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).removeValue()
        }
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Monitor the user that was passed to the controller and update view with their information
        rootRef.childByAppendingPath("users").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (snap) in
            self.username.text = snap.value["username"] as? String
            self.name.text = snap.value["name"] as? String
            self.email.text = snap.value["email"] as? String
            self.age.text = snap.value["age"] as? String
            self.gender.text = snap.value["gender"] as? String
            
            let base64EncodedString = snap.value["profilePicture"]
            if let imageString = base64EncodedString! {
                let imageData = NSData(base64EncodedString: imageString as! String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                self.profilePicture.image = decodedImage
            }
            
            currentUser.childByAppendingPath("friends").childByAppendingPath(snap.value["username"] as? String).observeEventType(.Value, withBlock: { (snap) in
                if snap.value is NSNull {
                    self.isCurrentFriend = false
                } else {
                    self.isCurrentFriend = true
                }
            }) { (error) in
                print(error.description)
            }

        }) { (error) in
                print(error.description)
        }
        
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
