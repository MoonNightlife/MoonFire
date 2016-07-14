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


class UserProfileViewController: UIViewController, iCarouselDelegate, iCarouselDataSource {
    
    // MARK: - Properties
    
    var privacyLabel = UILabel()
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
                        self.carousel.hidden = true
                        self.privacyLabel.hidden = false
                    }
                })
            }
            if newValue == "off" {
                carousel.hidden = false
                self.privacyLabel.hidden = true
            }
        }
    }
    
    // MARK: - Size Changing Variables
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    
    // MARK: - Outlets
    let barButton  = UIButton()
    let friendsButton  = UIButton()
    let favBarButton  = UIButton()
    let bioLabel = UILabel()
    let birthdayLabel = UILabel()
    let drinkLabel = UILabel ()
    let username = UILabel()
    let currentBarImage = UIImageView()
    let favoriteBarImage = UIImageView()
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
  
    @IBOutlet weak var requestButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var cityCoverConstraint: NSLayoutConstraint!
    @IBOutlet weak var picWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var picHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameConstraint: NSLayoutConstraint!
    
    @IBOutlet var carousel: iCarousel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var cityCoverImage: UIImageView!
    @IBOutlet weak var addFriendButton: UIButton!
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
        currentUser.childByAppendingPath("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("friendRequest/\(self.userID)").childByAppendingPath(snap.value as! String).setValue(currentUser.key)
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func unfriendUser() {
        // Removes the username and ID of the users from underneath their friend list
        // Also removes the users bar activity from each others bar feed
        currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).removeValue()
        currentUser.childByAppendingPath("barFeed").childByAppendingPath(self.userID).removeValue()
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("users").childByAppendingPath(self.userID).childByAppendingPath("friends").childByAppendingPath(snap.value["username"] as! String).removeValue()
            rootRef.childByAppendingPath("users").childByAppendingPath(self.userID).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    func acceptFriendRequest() {
        currentUser.childByAppendingPath("friends").childByAppendingPath(self.username.text).setValue(self.userID)
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("users/\(self.userID)/friends").childByAppendingPath(snap.value["username"] as! String).setValue(snap.key)
            rootRef.childByAppendingPath("friendRequest").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).childByAppendingPath(self.username.text).removeValue()
            }, withCancelBlock: { (error) in
                print(error.description)
        })
        
    }

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Cosnstraints
        let picSize = self.view.frame.size.height / 4.168
        picHeightConstraint.constant = picSize
        picWidthConstraint.constant = picSize
        profilePicture.frame.size.width = picSize
        profilePicture.frame.size.height = picSize
        
        cityCoverConstraint.constant = self.view.frame.size.height / 5.02
        cityCoverImage.frame.size.height = self.view.frame.size.height / 5.02
        
        nameConstraint.constant = self.view.frame.size.height / 3.93
        name.frame.size.height = self.view.frame.size.height / 31.76
        name.frame.size.width = self.view.frame.size.height / 3.93
        
        requestButtonConstraint.constant = self.view.frame.size.height / 3.93
        addFriendButton.frame.size.width = self.view.frame.size.height / 3.93
        addFriendButton.frame.size.height = buttonHeight
        
        //initializing size changing variables
        labelBorderSize = self.view.frame.size.height / 22.23
        buttonHeight = self.view.frame.size.height / 33.35
        fontSize = self.view.frame.size.height / 47.64
        
        //sets a circular profile pic
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        
        //carousel set up
        carousel.type = .Linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        //sets the navigation control colors
        navigationItem.backBarButtonItem?.tintColor = UIColor.darkGrayColor()
        navigationItem.titleView?.tintColor = UIColor.darkGrayColor()
        
        //name label set up
        name.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.font = name.font.fontWithSize(self.view.frame.size.height / 44.47)
        name.layer.cornerRadius = 5
       
        //city label set up
        cityLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityLabel)
        cityLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityLabel)
        cityLabel.layer.cornerRadius = 5
        
        //set up city cover image
        cityCoverImage.layer.borderColor = UIColor.whiteColor().CGColor
        cityCoverImage.layer.borderWidth = 1
        cityCoverImage.layer.cornerRadius = 5
        
        //add friend button
        addFriendButton.setTitle("", forState: UIControlState.Normal)
        addFriendButton.layer.borderWidth = 1
        addFriendButton.layer.cornerRadius = 5
        addFriendButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
        
        //sets the title of the view
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        
        
        //Privacy label set up
        privacyLabel = UILabel(badgeText: "Private", color: UIColor.whiteColor(), fontSize: fontSize)
        privacyLabel.frame = CGRect(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2, width: 100, height: 20)
        privacyLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: privacyLabel)
        privacyLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: privacyLabel)
        privacyLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: privacyLabel)
        privacyLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: privacyLabel)
        privacyLabel.font = privacyLabel.font.fontWithSize(self.view.frame.size.height / 44.47)
        privacyLabel.layer.cornerRadius = 5
        self.view.addSubview(privacyLabel)
        
        

    }
    
    func getProfileInformation() {
        
        getUsersCurrentBar()
        
        // Monitor the user that was passed to the controller and update view with their information
        rootRef.childByAppendingPath("users").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (userSnap) in
            
            self.username.text = userSnap.value["username"] as? String
            self.navigationItem.title = userSnap.value["username"] as? String
            self.name.text = userSnap.value["name"] as? String
            self.name.text = userSnap.value["name"] as? String
            self.bioLabel.text = userSnap.value["bio"] as? String
            self.drinkLabel.text = "Favorite Drink: " + (userSnap.value["favoriteDrink"] as? String ?? "")
            self.birthdayLabel.text = userSnap.value["age"] as? String
            self.isPrivacyOn = userSnap.value["privacy"] as? String
            
            // Loads the users last city to the view
            let cityData = userSnap.childSnapshotForPath("cityData")
            if let cityImage = cityData.value["picture"] as? String {
                self.cityCoverImage.image = stringToUIImage(cityImage, defaultString: "dallas_skyline.jpeg")
            }
            if let cityName = cityData.value["name"] as? String {
                self.cityLabel.text = cityName
            } else {
                self.cityLabel.text = " Unknow City"
            }
            
            
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
    
    func getUsersCurrentBar() {
        rootRef.childByAppendingPath("barActivities").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.barButton.setTitle(snap.value["barName"] as? String, forState: .Normal)
                self.currentBarID = snap.value["barID"] as? String
                
                
                // Get the number of users going
                rootRef.childByAppendingPath("bars").childByAppendingPath(snap.value["barID"] as? String).observeSingleEventOfType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull) {
                        let usersGoing = snap.value["usersGoing"] as? Int ?? 0
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
                self.carousel.reloadData()
            }
        }) { (error) in
            print(error)
        }
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
        currentUser.childByAppendingPath("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("friendRequest").childByAppendingPath(self.userID).childByAppendingPath(snap.value as! String).observeEventType(.Value, withBlock: { (snap) in
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

            }) { (error) in
                print(error)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFriendsFromSearch" {
            let vc = segue.destinationViewController as! FriendsTableViewController
            vc.currentUser = rootRef.childByAppendingPath("users").childByAppendingPath(userID)
        }
        if segue.identifier == "userProfileToBarProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

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
    
    //MARK: Carousel Functions
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return numberOfCarousels
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        var label: UILabel
        var itemView: UIImageView
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame:CGRect(x:0, y:0, width:carousel.frame.width, height:carousel.frame.height))
            //itemView.image = UIImage(named: "page.png")
            itemView.backgroundColor = UIColor(red: 0 , green: 0, blue: 0, alpha: 0.5)
            itemView.layer.cornerRadius = 5
            itemView.layer.borderWidth = 1
            itemView.layer.borderColor = UIColor.whiteColor().CGColor
            itemView.userInteractionEnabled = true
            itemView.contentMode = .Center
            
            // Bar going to view
            if (index == 0){
                
                bioLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
                bioLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 10)
                bioLabel.backgroundColor = UIColor.clearColor()
                bioLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                bioLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                bioLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                bioLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                bioLabel.layer.cornerRadius = 5
                bioLabel.font = bioLabel.font.fontWithSize(fontSize)
                bioLabel.textColor = UIColor.whiteColor()
                bioLabel.textAlignment = NSTextAlignment.Center
                itemView.addSubview(bioLabel)
                
                birthdayLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
                birthdayLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 3.5)
                birthdayLabel.backgroundColor = UIColor.clearColor()
                birthdayLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                birthdayLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                birthdayLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                birthdayLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                birthdayLabel.layer.cornerRadius = 5
                birthdayLabel.font = bioLabel.font.fontWithSize(fontSize)
                birthdayLabel.textColor = UIColor.whiteColor()
                birthdayLabel.textAlignment = NSTextAlignment.Center
                itemView.addSubview(birthdayLabel)
                
                drinkLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
                drinkLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 2 )
                drinkLabel.backgroundColor = UIColor.clearColor()
                drinkLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                drinkLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                drinkLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                drinkLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                drinkLabel.layer.cornerRadius = 5
                drinkLabel.font = bioLabel.font.fontWithSize(fontSize)
                drinkLabel.textColor = UIColor.whiteColor()
                drinkLabel.textAlignment = NSTextAlignment.Center
                itemView.addSubview(drinkLabel)
                
                
                friendsButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
                friendsButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.4)
                friendsButton.backgroundColor = UIColor.clearColor()
                friendsButton.layer.borderWidth = 1
                friendsButton.layer.borderColor = UIColor.whiteColor().CGColor
                friendsButton.layer.cornerRadius = 5
                friendsButton.setTitle("Friends", forState: UIControlState.Normal)
                friendsButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                friendsButton.userInteractionEnabled = true
                friendsButton.addTarget(self, action: #selector(UserProfileViewController.viewFriends), forControlEvents: .TouchUpInside)
                friendsButton.enabled = true
                friendsButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                itemView.addSubview(friendsButton)
                
  
                
            }
            
            //info view
            if (index == 1){
                
                currentBarImage.layer.borderColor = UIColor.whiteColor().CGColor
                currentBarImage.layer.borderWidth = 1
                currentBarImage.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                currentBarImage.layer.cornerRadius = 5
                itemView.addSubview(currentBarImage)
                
                // Indicator for current bar picture
                currentBarIndicator.center = CGPointMake(self.currentBarImage.frame.size.width / 2, self.currentBarImage.frame.size.height / 2)
                currentBarImage.addSubview(self.currentBarIndicator)
                self.currentBarIndicator.startAnimating()
                
                barButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
                barButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.4)
                barButton.backgroundColor = UIColor.clearColor()
                barButton.layer.borderWidth = 1
                barButton.layer.borderColor = UIColor.whiteColor().CGColor
                barButton.layer.cornerRadius = 5
                barButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                barButton.userInteractionEnabled = true
                barButton.enabled = true
                barButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                barButton.addTarget(self, action: #selector(ProfileViewController.showBar), forControlEvents: .TouchUpInside)
                itemView.addSubview(barButton)
                
                currentPeopleGoing.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
                currentPeopleGoing.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.1 )
                currentPeopleGoing.backgroundColor = UIColor.clearColor()
                currentPeopleGoing.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                currentPeopleGoing.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                currentPeopleGoing.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                currentPeopleGoing.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
                currentPeopleGoing.layer.cornerRadius = 5
                currentPeopleGoing.font = bioLabel.font.fontWithSize(fontSize)
                currentPeopleGoing.textColor = UIColor.whiteColor()
                currentPeopleGoing.textAlignment = NSTextAlignment.Center
                itemView.addSubview(currentPeopleGoing)
                
            }
            
            //favorite bar view
            if (index == 2){
                
    
                favoriteBarImage.layer.borderColor = UIColor.whiteColor().CGColor
                favoriteBarImage.layer.borderWidth = 1
                favoriteBarImage.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                favoriteBarImage.layer.cornerRadius = 5
                itemView.addSubview(favoriteBarImage)
                
                favBarButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
                favBarButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                favBarButton.backgroundColor = UIColor.clearColor()
                favBarButton.layer.borderWidth = 1
                favBarButton.layer.borderColor = UIColor.whiteColor().CGColor
                favBarButton.layer.cornerRadius = 5
                favBarButton.setTitle("Fav Bar", forState: UIControlState.Normal)
                favBarButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                favBarButton.userInteractionEnabled = true
                favBarButton.enabled = true
                favBarButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                itemView.addSubview(favBarButton)
                
                
                
                
            }
            
            
            label = UILabel(frame:itemView.bounds)
            label.backgroundColor = UIColor.clearColor()
            label.textAlignment = .Center
            label.font = label.font.fontWithSize(50)
            label.tag = 1
            //itemView.addSubview(label)
        }
        else
        {
            //get a reference to the label in the recycled view
            itemView = view as! UIImageView;
            label = itemView.viewWithTag(1) as! UILabel!
        }
        
        return itemView
    }
    
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        return value
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
