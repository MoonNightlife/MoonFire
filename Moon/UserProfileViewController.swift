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
import QuartzCore
import GoogleMaps


class UserProfileViewController: UIViewController  {
    
    // MARK: - Properties
    
    var handles = [UInt]()
    
   
    let currentPeopleGoing = UILabel()
    var userID: String!
    var isCurrentFriend: Bool = false
    var hasFriendRequest: Bool = false
    var sentFriendRequest: Bool = false
    var currentBarID: String?
    var numberOfCarousels = 2
    let currentUserID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    let placeClient = GMSPlacesClient()
    var isPrivacyOn: String? = "off" {
        willSet {
            if newValue == "on" {
                checkIfFriendBy(userID, handler: { (isFriend) in
                    if !isFriend {
                        
                        self.privacyLabel.hidden = false
                    }
                })
            }
            if newValue == "off" {
              
                self.privacyLabel.hidden = true
            }
        }
    }
    
    // MARK: - Size Changing Variables
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    
    // MARK: - Outlets

    
    let favBarButton  = UIButton()
   
    
    
    let username = UILabel()

    let favoriteBarImage = UIImageView()
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
  
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var barButton: UIButton!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var cityCoverImage: UIImageView!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var drinkLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var currentBarImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    //MARK: - Actions
    
    func viewFriends() {
        performSegueWithIdentifier("showFriendsFromSearch", sender: nil)
    }
   
    @IBAction func addFriend() {
        SwiftOverlays.showBlockingWaitOverlay()
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
            rootRef.child("friendRequest").child(self.userID).child(snap.value!["username"] as! String).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }

    func reloadFriendButton() {
        if !sentFriendRequest {
            if !isCurrentFriend {
                if !hasFriendRequest {
                    
                    self.addFriendButton.setTitle("Add Friend", forState: .Normal)
                    self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                    self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                    
                } else {
                    
                    self.addFriendButton.setTitle("Accept", forState: .Normal)
                    self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                    self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                }
            }else {
                isPrivacyOn = "off"
                self.addFriendButton.setTitle("Unfriend", forState: .Normal)
                self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                
            }
            
        } else {
            
            self.addFriendButton.setTitle("Cancel Request", forState: .Normal)
            self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
            self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        }
        SwiftOverlays.removeAllBlockingOverlays()
    }
    
    func sendFriendRequest() {
        // Send friend request
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("friendRequest/\(self.userID)").child(snap.value as! String).setValue(currentUser.key)
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func unfriendUser() {
        // Removes the username and ID of the users from underneath their friend list
        // Also removes the users bar activity from each others bar feed
        currentUser.child("friends").child(self.username.text!).removeValue()
        currentUser.child("barFeed").child(self.userID).removeValue()
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("users").child(self.userID).child("friends").child(snap.value!["username"] as! String).removeValue()
            rootRef.child("users").child(self.userID).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func acceptFriendRequest() {
        currentUser.child("friends").child(self.username.text!).setValue(self.userID)
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("users/\(self.userID)/friends").child(snap.value!["username"] as! String).setValue(snap.key)
            rootRef.child("friendRequest").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).child(self.username.text!).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
        
    }

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()

    }
    
    func setUpView(){
        
        //sets a circular profile pic
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        
        //scroll view set up
        //scroll view set up
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
        

        
    }
    
    func getProfileInformation() {
        
        getUsersCurrentBar()
        
        // Monitor the user that was passed to the controller and update view with their information
        let handle = rootRef.child("users").child(userID).observeEventType(.Value, withBlock: { (userSnap) in
            
        if let snap = userSnap.value {
            self.username.text = snap["username"] as? String
            self.navigationItem.title = snap["name"] as? String
            self.name.text = snap["name"] as? String
            self.name.text = snap["name"] as? String
            self.bioLabel.text = snap["bio"] as? String
            self.drinkLabel.text = (snap["favoriteDrink"] as? String ?? "")
            self.birthdayLabel.text = snap["age"] as? String
            self.isPrivacyOn = snap["privacy"] as? String
            
            // Loads the users last city to the view
            if let cityData = userSnap.childSnapshotForPath("cityData").value {
                if let cityImage = cityData["picture"] as? String {
                    self.cityCoverImage.image = stringToUIImage(cityImage, defaultString: "dallas_skyline.jpeg")
                }
                if let cityName = cityData["name"] as? String {
                    self.cityLabel.text = cityName
                }
            } else {
                self.cityLabel.text = " Unknown City"
            }
            
            
            let base64EncodedString = snap["profilePicture"]
            if let imageString = base64EncodedString! {
                let imageData = NSData(base64EncodedString: imageString as! String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                self.profilePicture.image = decodedImage
            }
        }
            
        }) { (error) in
            print(error.description)
        }
        handles.append(handle)
    }
    
    func getUsersCurrentBar() {
        let handle = rootRef.child("barActivities").child(userID).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.barButton.setTitle(snap.value!["barName"] as? String, forState: .Normal)
                self.currentBarID = snap.value!["barID"] as? String
                
                
                // Get the number of users going
                rootRef.child("bars").child(snap.value!["barID"] as! String).observeSingleEventOfType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull) {
                        let usersGoing = snap.value!["usersGoing"] as? Int ?? 0
                        self.currentPeopleGoing.text = "People Going: " + String(usersGoing)
                    }
                })
                
                if self.currentBarID != nil {
                    loadFirstPhotoForPlace(self.currentBarID!, imageView: self.currentBarImage, searchIndicator: self.currentBarIndicator)
                } else {
                    // If there is no current bar then stop the indicator and hide carousel
                    self.currentBarIndicator.stopAnimating()
                }
            } else {
                self.numberOfCarousels = 1
               
            }
        }) { (error) in
            print(error)
        }
        handles.append(handle)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Disable friend request button if user is looking at his own profile
        if currentUserID == userID {
            addFriendButton.enabled = false
            // Style button to look disabled
            addFriendButton.alpha = 0.3
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        SwiftOverlays.showBlockingWaitOverlay()
        getProfileInformation()
        checkIfUserIsFriend()
        checkForSentFriendRequest()
        checkForFriendRequest()
    }
    
    // Check is user is friend
    func checkIfUserIsFriend() {
        // Check friend status
        let handle = currentUser.child("friends").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
            if snap.value is NSNull {
                self.isCurrentFriend = false
                
                
            } else {
                self.isCurrentFriend = true
            }
            self.reloadFriendButton()
        }) { (error) in
            print(error.description)
        }
        handles.append(handle)
    }
    
    // Check if user is requesting to be your friend
    func checkForFriendRequest() {
        let handle = rootRef.child("friendRequest/\(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
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
        handles.append(handle)
    }
    
    func checkForSentFriendRequest() {
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            let handle = rootRef.child("friendRequest").child(self.userID).child(snap.value as! String).observeEventType(.Value, withBlock: { (snap) in
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
            self.handles.append(handle)
            }) { (error) in
                print(error)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFriendsFromSearch" {
            let vc = segue.destinationViewController as! FriendsTableViewController
            vc.currentUser = rootRef.child("users").child(userID)
        }
        if segue.identifier == "userProfileToBarProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    func showBar() {
        if let id = currentBarID {
            SwiftOverlays.showBlockingWaitOverlay()
            placeClient.lookUpPlaceID(id) { (place, error) in
                SwiftOverlays.removeAllBlockingOverlays()
                if let error = error {
                    print(error.description)
                }
                if let place = place {
                    self.performSegueWithIdentifier("userProfileToBarProfile", sender: place)
                }
            }
        }
    }
    

}
//MARK: - Class Extension
extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat, length: CGFloat, label: UILabel) {
        
        let border = CALayer()
        
        
        switch edge {
        case UIRectEdge.Top:
            border.frame = CGRectMake(self.frame.size.width - length, 0, length, thickness)
            break
        case UIRectEdge.Bottom:
            border.frame = CGRectMake(0, CGRectGetHeight(self.frame), length, thickness)
            break
        case UIRectEdge.Left:
            border.frame = CGRectMake(0, 0, thickness, length)
            break
        case UIRectEdge.Right:
            border.frame = CGRectMake(self.frame.size.width, -8, thickness, length)
            break
        default:
            break
        }
        
        border.backgroundColor = color.CGColor;
        
        self.addSublayer(border)
    }
    
}


