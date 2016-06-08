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
            border.frame = CGRectMake(CGRectGetWidth(self.frame) - thickness, -8, thickness, length)
            break
        default:
            break
        }
        
        border.backgroundColor = color.CGColor;
        
        self.addSublayer(border)
    }
    
}

class UserProfileViewController: UIViewController, iCarouselDelegate, iCarouselDataSource {
    
    // MARK: - Properties
    
    var userID: String!
    var isCurrentFriend: Bool = false
    var hasFriendRequest: Bool = false
    var sentFriendRequest: Bool = false
    
    // MARK: - Outlets
    let barButton   = UIButton()
    let friendsButton   = UIButton()
    let favBarButton   = UIButton()
    let addFriendButton = UIButton()
    let username = UILabel()
    
    @IBOutlet var carousel: iCarousel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var cityCoverImage: UIImageView!
    
    
    //MARK: - Actions
    
    func viewFriends() {
        performSegueWithIdentifier("showFriendsFromSearch", sender: nil)
    }
   
    func addFriend() {
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
    
    //carousel array
    var items: [Int] = []
    override func awakeFromNib()
    {
        super.awakeFromNib()
        for i in 0...3
        {
            items.append(i)
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
        
        //carousel set up
        carousel.type = .Rotary
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        //sets the navigation control colors
        navigationItem.backBarButtonItem?.tintColor = UIColor.darkGrayColor()
        navigationItem.titleView?.tintColor = UIColor.darkGrayColor()
        
        //name label set up
//        name.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: 50,)
//        name.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: 50)
//        name.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: 50)
//        name.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: 50)
//        name.layer.cornerRadius = 5
//        
//        
//        //city label set up
//        cityLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: 30)
//        cityLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: 30)
//        cityLabel.layer.cornerRadius = 5
        
        //set up city cover image
        cityCoverImage.layer.borderColor = UIColor.whiteColor().CGColor
        cityCoverImage.layer.borderWidth = 1
        cityCoverImage.layer.cornerRadius = 5
        

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
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int
    {
        return items.count
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView
    {
        var label: UILabel
        var itemView: UIImageView
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame:CGRect(x:0, y:0, width:240, height:180))
            //itemView.image = UIImage(named: "page.png")
            itemView.backgroundColor = UIColor(red: 0 , green: 0, blue: 0, alpha: 0.5)
            itemView.layer.cornerRadius = 5
            itemView.layer.borderWidth = 1
            itemView.layer.borderColor = UIColor.whiteColor().CGColor
            itemView.userInteractionEnabled = true
            itemView.contentMode = .Center
            
            if (index == 0){
                
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
                barButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, 220, 30)
                barButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                barButton.backgroundColor = UIColor.clearColor()
                barButton.layer.borderWidth = 1
                barButton.layer.borderColor = UIColor.whiteColor().CGColor
                barButton.layer.cornerRadius = 5
                barButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                barButton.userInteractionEnabled = true
                barButton.enabled = true
                itemView.addSubview(barButton)
                
            }
            
            if (index == 1){
                
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
                friendsButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, 220, 30)
                friendsButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                friendsButton.backgroundColor = UIColor.clearColor()
                friendsButton.layer.borderWidth = 1
                friendsButton.layer.borderColor = UIColor.whiteColor().CGColor
                friendsButton.layer.cornerRadius = 5
                friendsButton.setTitle("Friends", forState: UIControlState.Normal)
                friendsButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                friendsButton.userInteractionEnabled = true
                friendsButton.addTarget(self, action: #selector(ProfileViewController.showFriends), forControlEvents: .TouchUpInside)
                friendsButton.enabled = true
                itemView.addSubview(friendsButton)

            }
            
            
            if (index == 2){
                
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
                favBarButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, 220, 30)
                favBarButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                favBarButton.backgroundColor = UIColor.clearColor()
                favBarButton.layer.borderWidth = 1
                favBarButton.layer.borderColor = UIColor.whiteColor().CGColor
                favBarButton.layer.cornerRadius = 5
                favBarButton.setTitle("Fav Bar", forState: UIControlState.Normal)
                favBarButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                favBarButton.userInteractionEnabled = true
                favBarButton.enabled = true
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
    
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        return value
    }

}
