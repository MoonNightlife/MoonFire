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
import GeoFire
import SCLAlertView


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FlickrPhotoDownloadDelegate, CLLocationManagerDelegate{

    // MARK: - Properties
    
    let flickrService = FlickrServices()
    let tapPic = UITapGestureRecognizer()
    let cityRadius = 50.0
    var surroundingCities = [City]()
    var currentCity: City?
    var foundAllCities = (false, 0)
    var counter = 0
    let barButton   = UIButton()
    let friendsButton   = UIButton()
    let favBarButton   = UIButton()
    let bioLabel = UILabel()
    let birthdayLabel = UILabel()
    let drinkLabel = UILabel ()
    let placeClient = GMSPlacesClient()
    var currentBarID:String?
    let currentPeopleGoing = UILabel()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let locationManager = CLLocationManager()
    let cityImageIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    let currentBarImageView = UIImageView()
    let favoriteBarImageView = UIImageView()
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let privateLabel = UILabel()
    var numberOfCarousels = 2
    
    // MARK: - Outlets

    @IBOutlet weak var friendRequestButton: UIBarButtonItem!
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
    
    // MARK:- Flickr Photo Download
    
    func finishedDownloading(photos: [Photo]) {
        cityCoverImage.hnk_setImageFromURL(photos[0].imageURL)
    }
    
    func searchForPhotos() {
        flickrService.makeServiceCall("Dallas Skyline")
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flickrService.delegate = self
        
        labelSetup()

        //carousel set up
        carousel.type = .Linear
        carousel.currentItemIndex = 0
        carousel.delegate = self
        carousel.dataSource = self
        carousel.bounces = false
        carousel.backgroundColor = UIColor.clearColor()
        
        checkForFriendRequest()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Search for photos from flickr
        //searchForPhotos()
        
        // Find the location of the user and find the closest city
        locationManager.delegate = self
        cityImageIndicator.center = cityCoverImage.center
        cityImageIndicator.startAnimating()
        if locationManager.location == nil {
            locationManager.startUpdatingLocation()
        } else {
            queryForNearbyCities(locationManager.location!)
        }
        
        getUsersProfileInformation()
        
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

    func getUsersProfileInformation() {
        
        
        
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.getUsersCurrentBar()
            
            self.navigationItem.title = snap.value["username"] as? String
            
            self.name.text = snap.value["name"] as? String
            self.bioLabel.text = snap.value["bio"] as? String ?? "Update Bio In Settings"
            self.drinkLabel.text = "Favorite Drink: " + (snap.value["favoriteDrink"] as? String ?? "")
            self.birthdayLabel.text = snap.value["age"] as? String
            

            // Sets the profile picture
            self.indicator.stopAnimating()
            if let base64EncodedString = snap.value["profilePicture"] as? String {
                self.profilePicture.image = stringToUIImage(base64EncodedString, defaultString: "defaultPic")
            } else {
                //TODO: added picture giving instructions to click on photo
                self.profilePicture.image = UIImage(contentsOfFile: "defaultPic")
            }
            
        }) { (error) in
            print(error.description)
        }

    }

    func labelSetup() {
        
        // Cosnstraints
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
        
        // Initializing size changing variables
        labelBorderSize = self.view.frame.size.height / 22.23
        buttonHeight = self.view.frame.size.height / 33.35
        fontSize = self.view.frame.size.height / 47.64
        
        // Sets a circular profile pic
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        profilePicture.frame.size.height = self.view.frame.height / 4.45
        profilePicture.frame.size.width = self.view.frame.height / 4.45
        indicator.center = profilePicture.center
        profilePicture.addSubview(indicator)
        indicator.startAnimating()
        
        // Adds tap gesture
        tapPic.addTarget(self, action: #selector(ProfileViewController.tappedProfilePic))
        profilePicture.addGestureRecognizer(tapPic)
        profilePicture.userInteractionEnabled = true
        
        // Set up city cover image
        cityCoverImage.layer.borderColor = UIColor.whiteColor().CGColor
        cityCoverImage.layer.borderWidth = 1
        cityCoverImage.layer.cornerRadius = 5
        
        // Sets the navigation control colors
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.darkGrayColor()
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.lightGrayColor()
        self.navigationItem.titleView?.tintColor  = UIColor.lightGrayColor()
       self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        
        // Name label set up
        name.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: name)
        name.font = name.font.fontWithSize(self.view.frame.size.height / 44.47)
        name.layer.cornerRadius = 5
        
        // City label set up
        cityText.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityText)
        cityText.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: cityText)
        cityText.layer.cornerRadius = 5
        cityText.text = " Unknown City"
        
        createTestCity()
    }
    
    
    // MARK: - Friend Request Button
    
    func checkForFriendRequest() {
        // Checks for friends request so a badge can be added to the friend button on the top left of the profile
        rootRef.childByAppendingPath("friendRequest").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
            if snap.childrenCount == 0 {
                let image = UIImage(named: "AddFriend")
                let friendRequestBarButtonItem = UIBarButtonItem(badge: nil, image: image!, target: self, action: #selector(ProfileViewController.goToFriendRequestVC))
                self.navigationItem.leftBarButtonItem = friendRequestBarButtonItem
            } else {
                let image = UIImage(named: "AddFriend")
                let friendRequestBarButtonItem = UIBarButtonItem(badge: "\(snap.childrenCount)", image: image!, target: self, action: #selector(ProfileViewController.goToFriendRequestVC))
                self.navigationItem.leftBarButtonItem = friendRequestBarButtonItem
            }
            
        }) { (error) in
            print(error.description)
        }
    }
    
    func goToFriendRequestVC() {
        performSegueWithIdentifier("showFriendRequest", sender: self)
    }
    
    // MARK: - City Locater
    
    func createTestCity() {
//        let cityData = ["name":"Raleigh","image": createStringFromImage("raleigh_skyline.jpg")!]
//        rootRef.childByAppendingPath("cities").childByAutoId().setValue(cityData)
//        let location: CLLocation = CLLocation(latitude: 35.7796, longitude: -78.6382)
//        geoFireCity.setLocation(location, forKey: "-KKmsZZoLqnI2M-PfYKI")
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        queryForNearbyCities(locations.first!)
    }
    
    func queryForNearbyCities(location: CLLocation) {
        counter = 0
        foundAllCities = (false,0)
        self.surroundingCities.removeAll()
        let circleQuery = geoFireCity.queryAtLocation(location, withRadius: cityRadius)
        circleQuery.observeEventType(.KeyEntered) { (key, location) in
            self.foundAllCities.1 += 1
            self.getCityInformation(key)
        }
        circleQuery.observeReadyWithBlock {
            self.foundAllCities.0 = true
            if self.foundAllCities.1 == 0 {
                self.cityText.text = " Unknown City"
                let cityData = ["name":" Unknown City","picture":createStringFromImage("dallas_skyline.jpeg")!]
                currentUser.childByAppendingPath("cityData").setValue(cityData)
                SCLAlertView().showError("Not in supported city", subTitle: "Moon is currently not avaible in your city")
            }
        }

    }
    
    func getCityInformation(id: String) {
        rootRef.childByAppendingPath("cities").childByAppendingPath(id).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            if !(snap.value is NSNull) {
                self.counter += 1
                self.surroundingCities.append(City(image: snap.value["image"] as? String, name: snap.value["name"] as? String))
                if self.foundAllCities.1 == self.counter && self.foundAllCities.0 == true {
                    if self.surroundingCities.count > 1 {
                        let citySelectView = SCLAlertView()
                        for city in self.surroundingCities {
                            citySelectView.addButton(city.name!, action: { 
                                self.cityText.text = city.name!
                                self.cityCoverImage.image = stringToUIImage(city.image!, defaultString: "dallas_skyline.jpeg")
                                let cityData = ["name":city.name!,"picture":city.image!]
                                currentUser.childByAppendingPath("cityData").setValue(cityData)
                            })
                        }
                        citySelectView.showNotice("Near Multiple Cities", subTitle: "Please select one")
                    } else {
                        // If there is only one nearby city then set that city aa currentCity and populate the view
                        self.currentCity = self.surroundingCities.first
                        // Add a
                        self.cityText.text = self.currentCity?.name
                      
                        self.cityCoverImage.stopAnimating()
                        self.cityCoverImage.image = stringToUIImage(self.currentCity!.image!, defaultString: "dallas_skyline.jpeg")
                        let cityData = ["name":self.currentCity!.name!,"picture":self.currentCity!.image!]
                        currentUser.childByAppendingPath("cityData").setValue(cityData)
                    }
                }
            }
            }) { (error) in
                print(error)
        }
    }
    
    // Gets the current bar and its accociated information to be displayed. If there is no current bar for the user then it hides that carousel
    func getUsersCurrentBar() {
        rootRef.childByAppendingPath("barActivities").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.numberOfCarousels = 2
                    self.carousel.reloadData()
                    self.barButton.setTitle(snap.value["barName"] as? String, forState: .Normal)
                    
                    // Get the number of users going
                    rootRef.childByAppendingPath("bars").childByAppendingPath(snap.value["barID"] as? String).observeSingleEventOfType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull) {
                            let usersGoing = snap.value["usersGoing"] as? Int ?? 0
                            self.currentPeopleGoing.text = "People Going: " + String(usersGoing)
                        }
                    })
        
                    self.currentBarID = snap.value["barID"] as? String
                    if self.currentBarID != nil {
                        loadFirstPhotoForPlace(self.currentBarID!, imageView: self.currentBarImageView, searchIndicator: self.currentBarIndicator)
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
    
    // MARK: - Image Selector
    
    func tappedProfilePic() {
        // Displays the photo library after the user taps on the profile picture
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        // Sets the photo in the view and saves to firebase after a photo is selected
        self.dismissViewControllerAnimated(true, completion: nil)
        
        profilePicture.image = image
        
        // Save image to firebase
        let imageData = UIImageJPEGRepresentation(image,0.1)
        let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        currentUser.childByAppendingPath("profilePicture").setValue(base64String)
    }

    
}

extension ProfileViewController: iCarouselDelegate, iCarouselDataSource {
    
    // MARK: - Carousel Functions
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return numberOfCarousels
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
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
                friendsButton.addTarget(self, action: #selector(ProfileViewController.showFriends), forControlEvents: .TouchUpInside)
                friendsButton.enabled = true
                friendsButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
                itemView.addSubview(friendsButton)
                
                
            }
            
            //info view
            if (index == 1){
                
                currentBarImageView.layer.borderColor = UIColor.whiteColor().CGColor
                currentBarImageView.layer.borderWidth = 1
                currentBarImageView.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                currentBarImageView.layer.cornerRadius = 5
                itemView.addSubview(currentBarImageView)
                
                // Indicator for current bar picture
                currentBarIndicator.center = CGPointMake(self.currentBarImageView.frame.size.width / 2, self.currentBarImageView.frame.size.height / 2)
                currentBarImageView.addSubview(self.currentBarIndicator)
                if currentBarImageView.image == nil {
                    self.currentBarIndicator.startAnimating()
                }
                
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
                
                favoriteBarImageView.layer.borderColor = UIColor.whiteColor().CGColor
                favoriteBarImageView.layer.borderWidth = 1
                favoriteBarImageView.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                favoriteBarImageView.layer.cornerRadius = 5
                itemView.addSubview(favoriteBarImageView)
                
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
    
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        return value
    }
}

