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
import Haneke
import PagingMenuController
import GoogleMaps
import SwiftOverlays

//MARK: - Class Extension


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FlickrPhotoDownloadDelegate, iCarouselDelegate, iCarouselDataSource{
    
    // MARK: - Properties
    
    let flickrService = FlickrServices()
    let tapPic = UITapGestureRecognizer()
    
    
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
    let placeClient = GMSPlacesClient()
    var currentBarID:String?
    
 
    @IBOutlet weak var cityCoverConstraint: NSLayoutConstraint!
    @IBOutlet weak var picWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var picHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityCoverImage: UIImageView!
    @IBOutlet weak var cityText: UILabel!
    @IBOutlet var carousel: iCarousel!

    
    // MARK: - Actions
    func showFriends() {
        print("clicking")
        performSegueWithIdentifier("showFriends", sender: nil)
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
                    self.performSegueWithIdentifier("barProfileFromUserProfile", sender: place)
                }
            }
        }
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
    
    // MARK:- Flickr Photo Download
    func finishedDownloading(photos: [Photo]) {
        cityCoverImage.hnk_setImageFromURL(photos[0].imageURL)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flickrService.delegate = self
        
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
        profilePicture.frame.size.height = self.view.frame.height / 4.45
        profilePicture.frame.size.width = self.view.frame.height / 4.45

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
        name.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.font = name.font.fontWithSize(self.view.frame.size.height / 44.47)
        name.layer.cornerRadius = 5

        
        
        
        //city label set up 
        cityText.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityText)
        cityText.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityText)
        cityText.layer.cornerRadius = 5

        //carousel set up
        carousel.type = .Linear
        carousel.currentItemIndex = 1
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
    }
    
    func getUsersCurrentBar() {
        rootRef.childByAppendingPath("barActivities").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.barButton.setTitle(snap.value["barName"] as? String, forState: .Normal)
                    self.currentBarID = snap.value["barID"] as? String
            }
        }) { (error) in
                print(error)
        }
    }
    
        
    func searchForPhotos() {
        flickrService.makeServiceCall("Dallas Skyline")
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Uncomment to search for photos from flickr
        //searchForPhotos()
        
        // Finds the current users information and populates the view
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.getUsersCurrentBar()
            
            self.navigationItem.title = snap.value["username"] as? String
            
            self.name.text = snap.value["name"] as? String
            self.bioLabel.text = snap.value["bio"] as? String
            self.drinkLabel.text = snap.value["favoriteDrink"] as? String
            self.birthdayLabel.text = snap.value["age"] as? String
            
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
        
    }
    
    // Displays the photo library after the user taps on the profile picture
    func tappedProfilePic(){
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    // Sets the photo in the view and saves to firebase after a photo is selected
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
        if segue.identifier == "barProfileFromUserProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    //MARK: Carousel Functions
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int
    {
        return items.count
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView
    {
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
            barButton.addTarget(self, action: #selector(ProfileViewController.showBar), forControlEvents: .TouchUpInside)
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
            
            
        }
        else
        {
            //get a reference to the label in the recycled view
            itemView = view as! UIImageView;
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        //label.text = "\(items[index])"
        
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
