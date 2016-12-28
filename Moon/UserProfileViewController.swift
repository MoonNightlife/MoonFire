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
import GooglePlaces
import ObjectMapper


class UserProfileViewController: UIViewController  {
    
    // MARK: - Properties
    var handles = [UInt]()
    let currentPeopleGoing = UILabel()
    var userID: String!
    var isCurrentFriend: Bool? = nil
    var hasFriendRequest: Bool? = nil
    var sentFriendRequest: Bool? = nil
    var favoriteBarId: String? = nil
    var currentBarID: String? = nil
    let currentUserID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    let placeClient = GMSPlacesClient()
    var currentBarUsersHandle: UInt? = nil
    var favortiteBarUsersHandle: UInt? = nil
    var isPrivacyOn: Bool? = false {
        willSet {
            if newValue == true {
                if !(currentUserID == userID) {
                    checkIfFriendBy(userID, handler: { (isFriend) in
                        if !isFriend {
                            self.privacyLabel.hidden = false
                            self.currentBarView.hidden = true
                            self.favoriteBarView.hidden = true
                        } else {
                            self.privacyLabel.hidden = true
                            self.currentBarView.hidden = false
                            self.favoriteBarView.hidden = false
                        }
                    })
                } else {
                    self.privacyLabel.hidden = true
                    self.currentBarView.hidden = false
                    self.favoriteBarView.hidden = false
                }
            }
            if newValue == false {
                self.privacyLabel.hidden = true
                self.currentBarView.hidden = false
                self.favoriteBarView.hidden = false
            }
        }
    }
    var currentUserUsername: String? = nil
    let favoriteBarImage = UIImageView()
    
    // MARK: - Outlet
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var barButton: UIButton!
    @IBOutlet weak var attendenceButton: UIButton!
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
    @IBOutlet weak var favoriteBarView: UIView!
    @IBOutlet weak var currentBarView: UIView!
    @IBOutlet weak var friendButtonImage: UIImageView!
    @IBOutlet weak var friendButtonIcon: UIImageView!
    @IBOutlet weak var favoriteBarImageView: UIImageView!
    @IBOutlet weak var currentBarUsersGoing: UILabel!
    @IBOutlet weak var favoriteBarUsersGoing: UILabel!
    @IBOutlet weak var goToFavoriteBar: UIButton!

    // MARK: - Actions
    @IBAction func goToFavoriteBarButton(sender: AnyObject) {
    if let id = favoriteBarId {
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
    
    @IBAction func imageTapped(sender: UITapGestureRecognizer) {
        performSegueWithIdentifier("showLargerPicture", sender: self)
    }
   
    @IBAction func viewFriends() {
        performSegueWithIdentifier("showFriendsFromSearch", sender: nil)
    }
   
    @IBAction func addFriend() {
        addFriendButton.userInteractionEnabled = false
        if !sentFriendRequest! {
            if !isCurrentFriend! {
                if !hasFriendRequest! {
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
    
    @IBAction func toggleGoingToCurrentBar(sender: AnyObject) {
        SwiftOverlays.showBlockingWaitOverlay()
        currentUser.child("name").observeEventType(.Value, withBlock: { (snap) in
            if let name = snap.value {
                changeAttendanceStatus(self.currentBarID!, userName: name as! String)
            }
        }) { (error) in
            print(error.description)
        }
    }
    
    @IBAction func showBar() {
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
    
    // MARK: - Helper methods for adding friends
    func cancelFriendRequest() {
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("friendRequest").child(self.userID).child((snap.value as! NSDictionary)["username"] as! String).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }

    func reloadFriendButton() {
        if !sentFriendRequest! {
            if !isCurrentFriend! {
                if !hasFriendRequest! {
                    
                    self.addFriendButton.setTitle("Add", forState: .Normal)
                    self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                    self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                    
                } else {
                    
                    self.addFriendButton.setTitle("Accept", forState: .Normal)
                    self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                    self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                }
            }else {
                isPrivacyOn = false
                self.addFriendButton.setTitle("Remove", forState: .Normal)
                self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                
            }
            
        } else {
            
            self.addFriendButton.setTitle("Cancel", forState: .Normal)
            self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
            self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        }
       addFriendButton.userInteractionEnabled = true
    }
    
    func sendFriendRequest() {
        // Send friend request
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("friendRequest/\(self.userID)").child(snap.value as! String).setValue(currentUser.key)
        
        //push notification after adding friend
        sendPush(false, badgeNum: 1, groupId: "Friend Requests", title: "Moon", body: "New friend fequest from " + String(snap.value as! String), customIds: [self.userID!], deviceToken: "nil")
            
            }, withCancelBlock: { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })
    }
    
    func unfriendUser() {
        // Removes the username and ID of the users from underneath their friend list
        // Also removes the users bar activity from each others bar feed
        currentUser.child("friends").child(self.currentUserUsername!).removeValue()
        currentUser.child("barFeed").child(self.userID).removeValue()
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("users").child(self.userID).child("friends").child((snap.value as! NSDictionary)["username"] as! String).removeValue()
            rootRef.child("users").child(self.userID).child("barFeed").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
            }, withCancelBlock: { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })
    }
    
    func acceptFriendRequest() {
        currentUser.child("friends").child(self.currentUserUsername!).setValue(self.userID)
        exchangeCurrentBarActivitesWithCurrentUser(self.userID)
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.child("users/\(self.userID)/friends").child((snap.value  as! NSDictionary)["username"] as! String).setValue(snap.key)
            rootRef.child("friendRequest").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).child(self.currentUserUsername!).removeValue()
            
        //push notification after accepting
        sendPush(false, badgeNum: 1, groupId: "Friend Requests", title: "Moon", body: String((snap.value as! NSDictionary)["username"] as! String) + " has accepted your friend request", customIds: [self.userID!], deviceToken: "nil")
            
            }, withCancelBlock: { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })
        
    }

    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        attendenceButton.hidden = true
        setUpView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Disable friend request button if user is looking at his own profile
        if currentUserID == userID {
            addFriendButton.enabled = false
            // Style button to look disabled
            addFriendButton.alpha = 0.3
            friendButtonIcon.alpha = 0.3
            friendButtonImage.alpha = 0.3
        }
        setUpNavigation()
        
        getProfileInformation()
        
        
        // Disable friend request button until everything is loaded
        addFriendButton.setTitle("Loading", forState: .Normal)
        addFriendButton.userInteractionEnabled = false
        checkIfUserIsFriend()
        checkForSentFriendRequest()
        checkForFriendRequest()
        
        
        getProfilePictureForUserId(userID, imageView: profilePicture)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        
        if segue.identifier == "showLargerPicture" {
            let vc = (segue.destinationViewController as! UINavigationController).topViewController as! LargePhotoViewController
            vc.userId = userID
        }
        
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
        // Removes the old observer for users going
        if let hand = currentBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        if let hand = favortiteBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
    }
    
    // MARK: - Helper functions for view
    func setUpView() {
        
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
    
    func setUpNavigation() {
        
        //navigation controller set up
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        //Top View set up
        let header = "Title_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
    }
    
    func getProfileInformation() {
        
        // Monitor the user that was passed to the controller and update view with their information
        let handle = rootRef.child("users").child(userID).observeEventType(.Value, withBlock: { (userSnap) in
          
            if !(userSnap.value is NSNull),let userProfileInfo = userSnap.value as? [String : AnyObject] {
                
                let userId = Context(id: userSnap.key)
                let user = Mapper<User2>(context: userId).map(userProfileInfo)
                
                if let user = user {
                    self.drinkLabel.text = user.favoriteDrink
                    self.birthdayLabel.text = user.birthday
                    self.isPrivacyOn = user.privacy
                    self.currentUserUsername = user.username
                    
                    self.navigationItem.title = (user.name ?? "") + " " + (genderSymbolFromGender(user.sex) ?? "")
                    
                    if let bio = user.bio {
                        self.bioLabel.backgroundColor = nil
                        self.bioLabel.text = bio
                    } else {
                        self.bioLabel.text = nil
                        self.bioLabel.backgroundColor = UIColor(patternImage: UIImage(named: "bio_line.png")!)
                    }
                    
                    if let city = user.cityData {
                        getCityPictureForCityId(city.cityId!, imageView: self.cityCoverImage)
                        self.cityLabel.text = city.name
                    } else {
                        self.cityLabel.text = "Unknown City"
                    }
                    
                    // Every time a users current bar this code will be executed to go grab the current bar information
                    
                    if let currentBarId = user.currentBarId {
                        getActivityForUserId(self.userID, handle: { (activity) in
                            if seeIfShouldDisplayBarActivity(activity) {
                                // If the current bar is the same from the last current bar it looked at then dont do anything
                                if currentBarId != self.currentBarID {
                                    self.currentBarID = currentBarId
                                    self.attendenceButton.hidden = false
                                    self.currentBarUsersGoing.hidden = false
                                    self.observeCurrentBarWithId(currentBarId)
                                    self.observeIfUserIsGoingToBarShownOnScreen(currentBarId)
                                } 
                            } else {
                                self.removeCurrentBarImages()
                            }
                        })
                    } else {
                        self.removeCurrentBarImages()
                    }
                    
                    // Every time a users favorite bar changes this code will be executed to go grab the current bar information
                    if let favoriteBarId = user.favoriteBarId {
                        // If the current bar is the same from the last current bar it looked at then dont do anything
                        if favoriteBarId != self.favoriteBarId {
                            self.observeFavoriteBarWithId(favoriteBarId)
                            self.favoriteBarId = favoriteBarId
                        }
                    } else {
                        self.favoriteBarImageView.image = UIImage(named: "Default_Image.png")
                        self.goToFavoriteBar.setTitle("No Favorite Bar", forState: .Normal)
                        self.favoriteBarId = nil
                        self.favoriteBarUsersGoing.text = nil
                        
                    }
                } else {
                    self.navigationItem.title = "User Not Found"
                    self.addFriendButton.enabled = false
                    // Style button to look disabled
                    self.addFriendButton.alpha = 0.3
                    self.friendButtonIcon.alpha = 0.3
                    self.friendButtonImage.alpha = 0.3
                }
            }

            
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }
    
    func removeCurrentBarImages() {

        self.currentBarImage.image = UIImage(named: "Default_Image.png")
        self.barButton.setTitle("No Plans", forState: .Normal)
        self.attendenceButton.hidden = true
        if let handle = self.currentBarUsersHandle {
            rootRef.removeObserverWithHandle(handle)
            self.currentBarUsersHandle = nil
        }
        self.currentBarUsersGoing.hidden = true
        self.currentBarID = nil
        
    }
    
    func observeCurrentBarWithId(barId: String) {
        
    
        // First load image since the bar image won't be changing between method calls
        loadFirstPhotoForPlace(barId, imageView: self.currentBarImage, isSpecialsBarPic: false)
        
        // Removes the old observer for users going
        if let hand = self.currentBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        
        // Adds a new observer for the new BarId and set the labels
        let handle = rootRef.child("bars").child(barId).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let bar = snap.value as? [String : AnyObject] {
                
                let barId = Context(id: snap.key)
                let bar = Mapper<Bar2>(context: barId).map(bar)
                
                if let bar = bar {
                    
                    getNumberOfUsersGoingBasedOffBarValidBarActivities(bar.barId!, handler: { (numOfUsers) in
                        self.currentBarUsersGoing.text = String(numOfUsers)
                    })
                    
                    self.barButton.setTitle(bar.barName, forState: .Normal)
                }
                
            }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        
        // Sets global handle for the current BarId
        self.currentBarUsersHandle = handle
     
        
        

    }
    
    func observeFavoriteBarWithId(barId: String) {
        
        // First load image since the bar image won't be changing between method calls
        // TODO: setup real activity indicator
        loadFirstPhotoForPlace(barId, imageView: favoriteBarImageView, isSpecialsBarPic: false)
        
        // Removes the old observer for users going
        if let hand = favortiteBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        
        // Adds a new observer for the new BarId and set the labels
        let handle = rootRef.child("bars").child(barId).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let bar = snap.value {
                
                let barId = Context(id: snap.key)
                let bar = Mapper<Bar2>(context: barId).map(bar)
                
                if let bar = bar {
                    
                    getNumberOfUsersGoingBasedOffBarValidBarActivities(bar.barId!, handler: { (numOfUsers) in
                        self.favoriteBarUsersGoing.text = String(numOfUsers)
                    })
                
                    self.goToFavoriteBar.setTitle(bar.barName, forState: .Normal)
                }
                
            }
        }) { (error) in
            print(error.description)
        }
        
        // Sets global handle for the current BarId
        favortiteBarUsersHandle = handle
    }

    func checkIfUserIsFriend() {
        // Check friend status
        let handle = currentUser.child("friends").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
            if snap.value is NSNull {
                self.isCurrentFriend = false
            } else {
                self.isCurrentFriend = true
            }
            if self.isCurrentFriend != nil && self.hasFriendRequest != nil && self.sentFriendRequest != nil {
                self.reloadFriendButton()
            }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }
    
    func checkForFriendRequest() {
        let handle = rootRef.child("friendRequest/\(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)").queryOrderedByValue().queryEqualToValue(self.userID).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.hasFriendRequest = true
            } else {
                self.hasFriendRequest = false
            }
            if self.isCurrentFriend != nil && self.hasFriendRequest != nil && self.sentFriendRequest != nil {
                self.reloadFriendButton()
            }
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
                if self.isCurrentFriend != nil && self.hasFriendRequest != nil && self.sentFriendRequest != nil {
                    self.reloadFriendButton()
                }
                }, withCancelBlock: { (error
                    ) in
                    print(error.description)
            })
            self.handles.append(handle)
        }) { (error) in
            print(error)
        }
    }
    
    func observeIfUserIsGoingToBarShownOnScreen(barId: String) {
        let handle = currentUser.child("currentBar").observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let id = snap.value as? String {
                if id == barId {
                    self.attendenceButton.setTitle("Going", forState: .Normal)
                } else {
                    self.attendenceButton.setTitle("Go", forState: .Normal)
                }
            } else {
                self.attendenceButton.setTitle("Go", forState: .Normal)
            }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }

}




