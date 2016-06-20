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



class UserProfileViewController: UIViewController, iCarouselDelegate, iCarouselDataSource {
    
    // MARK: - Properties
    
    var userID: String!
    var isCurrentFriend: Bool = false
    var hasFriendRequest: Bool = false
    var sentFriendRequest: Bool = false
    
    // MARK: - Size Changing Variables
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    
    // MARK: - Outlets
    let barButton   = UIButton()
    let friendsButton   = UIButton()
    let favBarButton   = UIButton()
    let bioLabel = UILabel()
    let birthdayLabel = UILabel()
    let drinkLabel = UILabel ()
    let username = UILabel()
  
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
                
                self.addFriendButton.setTitle("Unfriend", forState: .Normal)
                self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
                self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                
            }
            
        } else {
            
            self.addFriendButton.setTitle("Cancel Request", forState: .Normal)
            self.addFriendButton.layer.borderColor = UIColor.whiteColor().CGColor
            self.addFriendButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
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
    
    //carousel array
    var items: [Int] = []
    override func awakeFromNib()
    {
        super.awakeFromNib()
        for i in 0...2
        {
            items.append(i)
        }
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
        
        

    }
    
    func getProfileInformation() {
        // Monitor the user that was passed to the controller and update view with their information
        
        rootRef.childByAppendingPath("users").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (userSnap) in
            self.username.text = userSnap.value["username"] as? String
            self.navigationItem.title = userSnap.value["username"] as? String
            self.name.text = userSnap.value["name"] as? String

            
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
    
    //MARK: Carousel Functions
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return items.count
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
                
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
                barButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
                barButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                barButton.backgroundColor = UIColor.clearColor()
                barButton.layer.borderWidth = 1
                barButton.layer.borderColor = UIColor.whiteColor().CGColor
                barButton.layer.cornerRadius = 5
                barButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                barButton.userInteractionEnabled = true
                barButton.enabled = true
                barButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                itemView.addSubview(barButton)
                
            }
            
            //info view
            if (index == 1){
                
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
                bioLabel.text = "SMU || FIJI || Engineering"
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
                birthdayLabel.text = "05 / 19 / 1995"
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
                drinkLabel.text = "Tequila"
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
                friendsButton.addTarget(self, action: #selector(ProfileViewController.showFriends), forControlEvents: .TouchUpInside)
                friendsButton.enabled = true
                friendsButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                itemView.addSubview(friendsButton)
                
            }
            
            //favorite bar view
            if (index == 2){
                
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
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
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "\(items[index])"
        
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
