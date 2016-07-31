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
import GooglePlaces
import SwiftOverlays
import GeoFire
import SCLAlertView
import Toucan


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FlickrPhotoDownloadDelegate, CLLocationManagerDelegate{

    // MARK: - Properties
    var handles = [UInt]()
    let flickrService = FlickrServices()
    let tapPic = UITapGestureRecognizer()
    let cityRadius = 50.0
    var surroundingCities = [City]()
    var currentCity: City?
    var foundAllCities = (false, 0)
    var counter = 0
    
 
    let favBarButton   = UIButton()

   
    let placeClient = GMSPlacesClient()
    var currentBarID:String?
    let currentPeopleGoing = UILabel()
    let genderLabel = UILabel()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let locationManager = CLLocationManager()
    let cityImageIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let favoriteBarImageView = UIImageView()
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let privateLabel = UILabel()
    var numberOfCarousels = 2
    var simulatedLocation: CLLocation? = nil
    var circleQuery: GFCircleQuery? = nil
    var currentBarUsersHandle: UInt?
    
    // MARK: - Outlets

    @IBOutlet weak var currentBarImageView: UIImageView!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var drinkLabel: UILabel!
    @IBOutlet weak var friendRequestButton: UIBarButtonItem!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cityText: UILabel!

    @IBOutlet weak var cityCoverImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
  
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var barButton: UIButton!
    
    
    // MARK: - Actions
    @IBAction func showFriends() {
        performSegueWithIdentifier("showFriends", sender: nil)
    }
    
    func showBar() {
        if let id = currentBarID {
            SwiftOverlays.showBlockingWaitOverlay()
            placeClient.lookUpPlaceID(id) { (place, error) in
                SwiftOverlays.removeAllBlockingOverlays()
                if let error = error {
                    showAppleAlertViewWithText(error.description, presentingVC: self)
                }
                if let place = place {
                    self.performSegueWithIdentifier("barProfileFromUserProfile", sender: place)
                }
            }
        }
    }
    
    func goToFriendRequestVC() {
        performSegueWithIdentifier("showFriendRequest", sender: self)
    }
    
    // MARK:- Flickr photo download
    func finishedDownloading(photos: [Photo]) {
        cityCoverImage.hnk_setImageFromURL(photos[0].imageURL)
    }
    
    func searchForPhotos() {
        flickrService.makeServiceCall("Dallas Skyline")
    }
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flickrService.delegate = self
        
        viewSetUp()
        
        // Add indicator for city image
        cityImageIndicator.center = cityCoverImage.center
        cityImageIndicator.startAnimating()
        
        // Find the location of the user and find the closest city
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        if locationManager.location == nil {
            // "queryForNearbyCities" is called after location is updated in "didUpdateLocations"
            locationManager.startUpdatingLocation()
        } else {
            queryForNearbyCities(locationManager.location!)
        }
        
        getProfilePictureForUserId(currentUser.key, imageView: profilePicture, indicator: indicator, vc: self)
    }
    
    
    func setUpNavigation(){
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        getUsersProfileInformation()
        checkForFriendRequest()
        setUpNavigation()
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove all the observers
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
        // This observer is handled differently beacuse it is changing all the time
        if let hand = currentBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
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

    // MARK: - Helper functions for view
    func getUsersProfileInformation() {
        
        let handle = currentUser.observeEventType(.Value, withBlock: { (snap) in
            
            if let userProfileInfo = snap.value {
                
                //male symbol
                let male: Character = "\u{2642}"
                
                //female symbole
                // let female: Character = "\u{2640}"
                
                //self.navigationItem.title = userProfileInfo["username"] 
                self.navigationItem.title = (userProfileInfo["name"] as? String) ?? " " + " " + String(male)
                self.bioLabel.text = userProfileInfo["bio"] as? String ?? "Update Bio In Settings"
                self.drinkLabel.text = (userProfileInfo["favoriteDrink"] as? String ?? "")
                self.birthdayLabel.text = userProfileInfo["age"] as? String
                self.genderLabel.text = userProfileInfo["gender"] as? String
                
                // Every time a users current bar changes this function will be called to go grab the current bar information
                // If there isnt a current bar at all then remove the tile(carousel) displaying it
                if let currentBarId = userProfileInfo["currentBar"] as? String {
                    // If the current bar is the same from the last current bar it looked at then dont do anything
                    if currentBarId != self.currentBarID {
                        self.getUsersCurrentBar()
                        self.observeNumberOfUsersGoingToBarWithId(currentBarId)
                    }
                }
            }
            
            //**** EVAN (Hi)*** The bioLabel has to have this image set when there is no bio
            self.bioLabel.backgroundColor = UIColor(patternImage: UIImage(named: "bio_line.png")!)
            

        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }

    func viewSetUp() {
        
        cityCoverImage.frame.size.height = self.view.frame.size.height / 5.02
        
        name.frame.size.height = self.view.frame.size.height / 31.76
        name.frame.size.width = self.view.frame.size.height / 3.93
        
        
        // Sets a circular profile pic
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        indicator.center = profilePicture.center
        profilePicture.backgroundColor = UIColor.clearColor()
        profilePicture.addSubview(indicator)
        indicator.startAnimating()
        
        
        // Adds tap gesture
        tapPic.addTarget(self, action: #selector(ProfileViewController.tappedProfilePic))
        profilePicture.addGestureRecognizer(tapPic)
        profilePicture.userInteractionEnabled = true
        
        
        //scroll view set up
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()

        
        cityText.text = "Unknown City"
     
    }

    func checkForFriendRequest() {
        // Checks for friends request so a badge can be added to the friend button on the top left of the profile
        let handle = rootRef.child("friendRequest").child((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(.Value, withBlock: { (snap) in
            if snap.childrenCount == 0 {
                let image = UIImage(named: "Add_Friend_Icon")
                let friendRequestBarButtonItem = UIBarButtonItem(badge: nil, image: image!, target: self, action: #selector(ProfileViewController.goToFriendRequestVC))
                self.navigationItem.leftBarButtonItem = friendRequestBarButtonItem
            } else {
                let image = UIImage(named: "Add_Friend_Icon")
                let friendRequestBarButtonItem = UIBarButtonItem(badge: "\(snap.childrenCount)", image: image!, target: self, action: #selector(ProfileViewController.goToFriendRequestVC))
                self.navigationItem.leftBarButtonItem = friendRequestBarButtonItem
            }
            
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        self.handles.append(handle)
    }
    
    func observeNumberOfUsersGoingToBarWithId(barId: String) {
        // Removes the old observer for users going
        if let hand = currentBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        // Adds a new observer for the new BarId and set the label
        let handle = rootRef.child("bars").child(barId).observeEventType(.Value, withBlock: { (snap) in
            if let usersGoing = snap.value {
                let usersGoing = usersGoing["usersGoing"] as! Int
                self.currentPeopleGoing.text = "People Going: " + String(usersGoing)
            }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        // Sets global handle for the current BarId
        currentBarUsersHandle = handle
    }
    
    func getUsersCurrentBar() {
        // Gets the current bar and its associated information to be displayed. If there is no current bar for the user then it hides that carousel
        rootRef.child("barActivities").child((FIRAuth.auth()?.currentUser?.uid)!).observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let barActivity = snap.value {
                self.numberOfCarousels = 2
                self.barButton.setTitle(barActivity["barName"] as? String, forState: .Normal)
                self.currentBarID = snap.value!["barID"] as? String
                loadFirstPhotoForPlace(self.currentBarID!, imageView: self.currentBarImageView, indicator: self.currentBarIndicator)
                
            }
            
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
    }
    
    // MARK: - City locater
    func locationManager(manager: CLLocationManager,  locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        queryForNearbyCities(locations.first!)
    }
    
    func queryForNearbyCities(location: CLLocation) {
        
        counter = 0
        foundAllCities = (false,0)
        self.surroundingCities.removeAll()
        // Get user simulated location if choosen, but if there isnt one then use location services on the phone
        currentUser.child("simLocation").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                let long = snap.value!["long"] as? Double
                let lat = snap.value!["lat"] as? Double
                if long != nil && lat != nil {
                    // TODO: coordinate to cllocation
                    self.simulatedLocation = CLLocation(latitude: lat!, longitude: long!)
                    self.circleQuery = geoFireCity.queryAtLocation(self.simulatedLocation, withRadius: self.cityRadius)
                }
            } else {
                self.circleQuery = geoFireCity.queryAtLocation(location, withRadius: self.cityRadius)
            }
            let handle = self.circleQuery!.observeEventType(.KeyEntered) { (key, location) in
                self.foundAllCities.1 += 1
                self.getCityInformation(key)
            }
            self.handles.append(handle)
            self.circleQuery!.observeReadyWithBlock {
                self.foundAllCities.0 = true
                // If there is no simulated location and we can't find a city near the user then prompt them with a choice
                // to go to settings and pick a city named location
                if self.foundAllCities.1 == 0 {
                    self.cityText.text = " Unknown City"
                    let cityData = ["name":" Unknown City","picture":createStringFromImage("dallas_skyline.jpeg")!]
                    currentUser.child("cityData").setValue(cityData)
                    let alertview = SCLAlertView()
                    alertview.addButton("Settings", action: {
                        self.performSegueWithIdentifier("showSettingsFromProfile", sender: self)
                    })
                    alertview.showError("Not in supported city", subTitle: "Moon is currently not avaible in your city, but you can select a city from user settings")
                }
            }
        })
    }
    
    func getCityInformation(id: String) {
        rootRef.child("cities").child(id).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            if !(snap.value is NSNull) {
                self.counter += 1
                self.surroundingCities.append(City(image: snap.value!["image"] as? String, name: snap.value!["name"] as? String, long: nil, lat: nil))
                if self.foundAllCities.1 == self.counter && self.foundAllCities.0 == true {
                    if self.surroundingCities.count > 1 {
                        let citySelectView = SCLAlertView()
                        for city in self.surroundingCities {
                            citySelectView.addButton(city.name!, action: { 
                                self.cityText.text = city.name!
                                self.cityCoverImage.image = stringToUIImage(city.image!, defaultString: "dallas_skyline.jpeg")
                                let cityData = ["name":city.name!,"picture":city.image!]
                                currentUser.child("cityData").setValue(cityData)
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
                        currentUser.child("cityData").setValue(cityData)
                    }
                }
            }
            }) { (error) in
                print(error)
        }
    }
    
    
    // MARK: - Image Selector
    
    // MARK: - Image selector
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
        
        let resizedImage = Toucan(image: image!).resize(CGSize(width: self.profilePicture.frame.size.width, height: self.profilePicture.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
        
        let maskImage = Toucan(image: resizedImage).maskWithEllipse(borderWidth: 1, borderColor: UIColor.whiteColor()).image
        
        self.profilePicture.image = maskImage
        
        // Save image to firebase storage
        let imageData = UIImageJPEGRepresentation(image!, 0.1)
        if let data = imageData {
            storageRef.child("profilePictures").child((FIRAuth.auth()?.currentUser?.uid)!).child("userPic").putData(data, metadata: nil) { (metaData, error) in
                if let error = error {
                    showAppleAlertViewWithText(error.description, presentingVC: self)
                }
            }
        } else {
            showAppleAlertViewWithText("Couldn't use image", presentingVC: self)
        }
        

//        let imageData = UIImageJPEGRepresentation(image,0.1)
//        let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
//        currentUser.child("profilePicture").setValue(base64String)
    }
    
}

//extension ProfileViewController: iCarouselDelegate, iCarouselDataSource {
//    
//    // MARK: - Carousel functions
//    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
//        return numberOfCarousels
//    }
//    
//    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
//        var itemView: UIImageView
//        
//        //create new view if no view is available for recycling
//        if (view == nil)
//        {
//            //don't do anything specific to the index within
//            //this `if (view == nil) {...}` statement because the view will be
//            //recycled and used with other index values later
//            itemView = UIImageView(frame:CGRect(x:0, y:0, width:carousel.frame.width, height:carousel.frame.height))
//            //itemView.image = UIImage(named: "page.png")
//            itemView.backgroundColor = UIColor(red: 0 , green: 0, blue: 0, alpha: 0.5)
//            itemView.layer.cornerRadius = 5
//            itemView.layer.borderWidth = 1
//            itemView.layer.borderColor = UIColor.whiteColor().CGColor
//            itemView.userInteractionEnabled = true
//            itemView.contentMode = .Center
//            
//            // Bar going to view
//            if (index == 0){
//                
//                bioLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
//                bioLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 10)
//                bioLabel.backgroundColor = UIColor.clearColor()
//                bioLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                bioLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                bioLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                bioLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                bioLabel.layer.cornerRadius = 5
//                bioLabel.font = bioLabel.font.fontWithSize(fontSize)
//                bioLabel.textColor = UIColor.whiteColor()
//                bioLabel.textAlignment = NSTextAlignment.Center
//                itemView.addSubview(bioLabel)
//                
//                birthdayLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
//                birthdayLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 3.5)
//                birthdayLabel.backgroundColor = UIColor.clearColor()
//                birthdayLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                birthdayLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                birthdayLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                birthdayLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                birthdayLabel.layer.cornerRadius = 5
//                birthdayLabel.font = bioLabel.font.fontWithSize(fontSize)
//                birthdayLabel.textColor = UIColor.whiteColor()
//                birthdayLabel.textAlignment = NSTextAlignment.Center
//                itemView.addSubview(birthdayLabel)
//                
//                drinkLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
//                drinkLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 2 )
//                drinkLabel.backgroundColor = UIColor.clearColor()
//                drinkLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                drinkLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                drinkLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                drinkLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                drinkLabel.layer.cornerRadius = 5
//                drinkLabel.font = bioLabel.font.fontWithSize(fontSize)
//                drinkLabel.textColor = UIColor.whiteColor()
//                drinkLabel.textAlignment = NSTextAlignment.Center
//                itemView.addSubview(drinkLabel)
//                
//                
//                friendsButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
//                friendsButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.4)
//                friendsButton.backgroundColor = UIColor.clearColor()
//                friendsButton.layer.borderWidth = 1
//                friendsButton.layer.borderColor = UIColor.whiteColor().CGColor
//                friendsButton.layer.cornerRadius = 5
//                friendsButton.setTitle("Friends", forState: UIControlState.Normal)
//                friendsButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
//                friendsButton.userInteractionEnabled = true
//                friendsButton.addTarget(self, action: #selector(ProfileViewController.showFriends), forControlEvents: .TouchUpInside)
//                friendsButton.enabled = true
//                friendsButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
//                itemView.addSubview(friendsButton)
//                
//                genderLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
//                genderLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.1 )
//                genderLabel.backgroundColor = UIColor.clearColor()
//                genderLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: genderLabel)
//                genderLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: genderLabel)
//                genderLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: genderLabel)
//                genderLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: genderLabel)
//                genderLabel.layer.cornerRadius = 5
//                genderLabel.font = bioLabel.font.fontWithSize(fontSize)
//                genderLabel.textColor = UIColor.whiteColor()
//                genderLabel.textAlignment = NSTextAlignment.Center
//                itemView.addSubview(genderLabel)
//                
//                
//            }
//            
//            //info view
//            if (index == 1){
//                
//                currentBarImageView.layer.borderColor = UIColor.whiteColor().CGColor
//                currentBarImageView.layer.borderWidth = 1
//                currentBarImageView.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
//                currentBarImageView.layer.cornerRadius = 5
//                itemView.addSubview(currentBarImageView)
//                
//                // Indicator for current bar picture
//                currentBarIndicator.center = CGPointMake(self.currentBarImageView.frame.size.width / 2, self.currentBarImageView.frame.size.height / 2)
//                currentBarImageView.addSubview(self.currentBarIndicator)
//                if currentBarImageView.image == nil {
//                    self.currentBarIndicator.startAnimating()
//                }
//                
//                barButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, buttonHeight)
//                barButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.4)
//                barButton.backgroundColor = UIColor.clearColor()
//                barButton.layer.borderWidth = 1
//                barButton.layer.borderColor = UIColor.whiteColor().CGColor
//                barButton.layer.cornerRadius = 5
//                barButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
//                barButton.userInteractionEnabled = true
//                barButton.enabled = true
//                barButton.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: fontSize)
//                barButton.addTarget(self, action: #selector(ProfileViewController.showBar), forControlEvents: .TouchUpInside)
//                itemView.addSubview(barButton)
//                
//                
//                currentPeopleGoing.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
//                currentPeopleGoing.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.1 )
//                currentPeopleGoing.backgroundColor = UIColor.clearColor()
//                currentPeopleGoing.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                currentPeopleGoing.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                currentPeopleGoing.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                currentPeopleGoing.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: bioLabel)
//                currentPeopleGoing.layer.cornerRadius = 5
//                currentPeopleGoing.font = bioLabel.font.fontWithSize(fontSize)
//                currentPeopleGoing.textColor = UIColor.whiteColor()
//                currentPeopleGoing.textAlignment = NSTextAlignment.Center
//                itemView.addSubview(currentPeopleGoing)
//            }
//
//
//
