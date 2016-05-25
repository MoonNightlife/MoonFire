//
//  ProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/18/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import QuartzCore

//MARK: - Class Extension

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat, length: CGFloat) {
        
        let border = CALayer()
        
        
        switch edge {
        case UIRectEdge.Top:
            border.frame = CGRectMake(220 - length, 0, length, thickness)
            break
        case UIRectEdge.Bottom:
            border.frame = CGRectMake(0, CGRectGetHeight(self.frame), length, thickness)
            break
        case UIRectEdge.Left:
            border.frame = CGRectMake(0, 0, thickness, length)
            break
        case UIRectEdge.Right:
            border.frame = CGRectMake(CGRectGetWidth(self.frame) - thickness, -15, thickness, length)
            break
        default:
            break
        }
        
        border.backgroundColor = color.CGColor;
        
        self.addSublayer(border)
    }
    
}

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, iCarouselDelegate, iCarouselDataSource{
    
    let tapPic = UITapGestureRecognizer()
    
    // MARK: - Outlets
   
    
    let barButton   = UIButton(type: UIButtonType.System) as UIButton
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityCoverImage: UIImageView!
    @IBOutlet weak var cityText: UILabel!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet var carousel: iCarousel!

    
    // MARK: - Actions
    @IBAction func showFriends() {
        performSegueWithIdentifier("showFriends", sender: nil)
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
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sets a circular profile pic
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true

        // Adds tap gesture
        tapPic.addTarget(self, action: #selector(ProfileViewController.tappedProfilePic))
        profilePicture.addGestureRecognizer(tapPic)
        profilePicture.userInteractionEnabled = true
        
        //set up city cover image
        cityCoverImage.layer.borderColor = UIColor.whiteColor().CGColor
        cityCoverImage.layer.borderWidth = 1
        cityCoverImage.layer.cornerRadius = 5
        

        
        //sets the navigation control colors
        navigationItem.rightBarButtonItem?.tintColor = UIColor.darkGrayColor()
        navigationItem.titleView?.tintColor = UIColor.darkGrayColor()
        
        //name label set up 
        name.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: 50)
        name.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: 50)
        name.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: 50)
        name.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: 50)
        name.layer.cornerRadius = 5
        
        //friends button set up 
        friendsButton.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: 30)
        friendsButton.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: 30)
        friendsButton.layer.cornerRadius = 5
        
        //city label set up 
        cityText.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: 30)
        cityText.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: 30)
        cityText.layer.cornerRadius = 5

        //carousel set up
        carousel.type = .Rotary
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Finds the current users information and populates the view
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
           self.navigationItem.title = snap.value["username"] as? String
        
            self.name.text = snap.value["name"] as? String
            
            if let barId = snap.value["currentBar"] {
                rootRef.childByAppendingPath("bars/\(barId)").childByAppendingPath("barName").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull) {
                        self.barButton.setTitle(snap.value as? String, forState: UIControlState.Normal)
                    }
                })
            }
            
            let base64EncodedString = snap.value["profilePicture"] as? String
            if let imageString = base64EncodedString {
                let imageData = NSData(base64EncodedString: imageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                self.profilePicture.image = decodedImage
            } else {
                self.profilePicture.image = UIImage(named: "defaultPic")
            }
            
            }) { (error) in
                print(error.description)
        }
        
        
        
    }
    
    // Displays the photo library after the user taps on the profile picture
    func tappedProfilePic(){
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    // Sets the photo in the view and firebase after a photo is selected
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        profilePicture.image = image
        
        // Save image to firebase
        let imageData = UIImageJPEGRepresentation(image,0.1)
        let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        currentUser.childByAppendingPath("profilePicture").setValue(base64String)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFriends" {
            let vc = segue.destinationViewController as! FriendsTableViewController
            vc.currentUser = currentUser
        }
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
            itemView.addSubview(barButton)
                
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
