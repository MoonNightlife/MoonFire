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
    var favoriteBarId: String? = nil

   
    let placeClient = GMSPlacesClient()
    var currentBarID:String?
    let currentPeopleGoing = UILabel()
    let genderLabel = UILabel()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let locationManager = CLLocationManager()
    let cityImageIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    let privateLabel = UILabel()
    var numberOfCarousels = 2
    var simulatedLocation: CLLocation? = nil
    var circleQuery: GFCircleQuery? = nil
    var currentBarUsersHandle: UInt?
    
    // MARK: - Outlets

    @IBOutlet weak var favoriteBarUsersGoingLabel: UILabel!
    @IBOutlet weak var favoriteBarButton: UIButton!
    @IBOutlet weak var favoriteBarImageView: UIImageView!
    @IBOutlet weak var goingToCurrentBarButton: UIButton!
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
    
    @IBOutlet weak var currentBarUsersGoing: UILabel!
    
    // MARK: - Actions
    @IBAction func updateBioButton(sender: AnyObject) {
        updateBio()
    }
    @IBAction func goToFavoriteBar(sender: AnyObject) {
        if let id = favoriteBarId {
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
    @IBAction func showFriends() {
        performSegueWithIdentifier("showFriends", sender: nil)
    }
    
    @IBAction func toggleGoingToBar(sender: AnyObject) {
        SwiftOverlays.showBlockingWaitOverlay()
        currentUser.child("name").observeEventType(.Value, withBlock: { (snap) in
            if let name = snap.value, let barId = self.currentBarID {
                changeAttendanceStatus(barId, userName: name as! String)
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
        
        //getProfilePictureForUserId(currentUser.key, imageView: profilePicture, indicator: indicator, vc: self)
        getProfilePictureForUserId(currentUser.key, imageView: profilePicture)
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
        
        if locationManager.location == nil {
            // "queryForNearbyCities" is called after location is updated in "didUpdateLocations"
            locationManager.startUpdatingLocation()
        } else {
            queryForNearbyCities(locationManager.location!)
        }
    
        getUsersProfileInformation()
        checkForFriendRequest()
        setUpNavigation()
        getUsersFavoriteBar(currentUser.key)
        
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
                
                // Use the correct gender symbol
                let male = "\u{2642}"
                let female = "\u{2640}"
                var genderChar: String?
                if let gender = userProfileInfo["gender"] as? String {
                    if gender == "male" {
                        genderChar = male
                    } else if gender == "female" {
                        genderChar = female
                    }
                } else {
                    genderChar = nil
                }
                
                self.navigationItem.title = ((userProfileInfo["name"] as? String) ?? "") + " " + (genderChar ?? "")
                
                self.drinkLabel.text = (userProfileInfo["favoriteDrink"] as? String ?? "")
                self.birthdayLabel.text = userProfileInfo["age"] as? String
                self.genderLabel.text = userProfileInfo["gender"] as? String
                
                if userProfileInfo["bio"] as? String != "",let bio = userProfileInfo["bio"] as? String {
                    self.bioLabel.backgroundColor = nil
                    self.bioLabel.text = bio
                } else {
                    self.bioLabel.text = nil
                    self.bioLabel.backgroundColor = UIColor(patternImage: UIImage(named: "bio_line.png")!)
                }
                
                // Every time a users current bar changes this function will be called to go grab the current bar information
                // If there isnt a current bar at all then remove the tile(carousel) displaying it
                if let currentBarId = userProfileInfo["currentBar"] as? String {
                    // If the current bar is the same from the last current bar it looked at then dont do anything
                    if currentBarId != self.currentBarID {
                        self.goingToCurrentBarButton.hidden = false
                        self.getUsersCurrentBar()
                        self.observeNumberOfUsersGoingToBarWithId(currentBarId)
                    }
                } else {
                    self.currentBarImageView.image = UIImage(named: "Default_Image.png")
                    self.barButton.setTitle("No Plans", forState: .Normal)
                    self.goingToCurrentBarButton.hidden = true
                    if let handle = self.currentBarUsersHandle {
                        rootRef.removeObserverWithHandle(handle)
                        self.currentBarUsersHandle = nil
                    }
                    self.currentBarUsersGoing.text = nil
                    self.currentBarID = nil
                }
            }

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
        let handle = rootRef.child("bars").child(barId).child("usersGoing").observeEventType(.Value, withBlock: { (snap) in
            if let usersGoing = snap.value as? Int {
                self.currentBarUsersGoing.text = String(usersGoing)
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
            if !(snap.value is NSNull),let barActivity = snap.value  {
                self.barButton.setTitle(barActivity["barName"] as? String, forState: .Normal)
                self.currentBarID = barActivity["barID"] as? String
                if let barId = self.currentBarID {
                    loadFirstPhotoForPlace(barId, imageView: self.currentBarImageView, indicator: self.currentBarIndicator, isSpecialsBarPic: false)
                }
            } else {
                
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
                    self.cityText.text = "Unknown City"
                    let cityData = ["name":"Unknown City","cityId":"-KKFSTnyQqwgQzFmEjcj"]
                    currentUser.child("cityData").setValue(cityData)
                    let alertview = SCLAlertView(appearance: K.Apperances.NormalApperance)
                    alertview.addButton("Settings", action: {
                        self.performSegueWithIdentifier("showSettingsFromProfile", sender: self)
                    })
                    alertview.showNotice("Not in supported city", subTitle: "Moon is currently not avaible in your city, but you can select a city from user settings")
                }
            }
        })
    }
    
    func getCityInformation(id: String) {
        rootRef.child("cities").child(id).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            if !(snap.value is NSNull), let city = snap.value {
                self.counter += 1
                self.surroundingCities.append(City(image: nil, name: city["name"] as? String, long: nil, lat: nil, id: snap.key))
                if self.foundAllCities.1 == self.counter && self.foundAllCities.0 == true {
                    self.currentCity = self.surroundingCities.first
                    
                    self.cityText.text = self.currentCity?.name
                  
                    self.cityCoverImage.startAnimating()
                    getCityPictureForCityId(self.currentCity!.id!, imageView: self.cityCoverImage, indicator: self.indicator, vc: self)
                    let cityData = ["name":self.currentCity!.name!,"cityId":self.currentCity!.id!]
                    currentUser.child("cityData").setValue(cityData)
                }
            }
            }) { (error) in
                print(error)
        }
    }
    
    func getUsersFavoriteBar(userId: String) {
        let handle = rootRef.child("users").child(userId).child("favoriteBarId").observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let favBarId = snap.value as? String {
                self.favoriteBarId = favBarId
                self.getBarInformationForBarId(favBarId)
            } else {
                self.favoriteBarImageView.image = UIImage(named: "Default_Image.png")
                self.favoriteBarButton.setTitle("No Favorite Bar", forState: .Normal)
                self.favoriteBarId = nil
                self.favoriteBarUsersGoingLabel.text = nil
            }
            }) { (error) in
                print(error.description)
        }
        handles.append(handle)
    }
    
    func getBarInformationForBarId(barId: String) {
        let indicater = UIActivityIndicatorView(activityIndicatorStyle: .White)
        loadFirstPhotoForPlace(barId, imageView: favoriteBarImageView, indicator: indicater, isSpecialsBarPic: false)
        rootRef.child("bars").child(barId).observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let barInfo = snap.value {
                let barName = barInfo["barName"] as? String
                self.favoriteBarButton.setTitle(barName, forState: .Normal)
                self.favoriteBarUsersGoingLabel.text = String(barInfo["usersGoing"] as! Int)
            }
            }) { (error) in
                print(error.description)
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
        
        let maskImage = Toucan(image: resizedImage).maskWithEllipse(borderWidth: 0, borderColor: UIColor.clearColor()).image
        
        self.profilePicture.image = maskImage
        
        // Save image to firebase storage
        
        let imageData = UIImageJPEGRepresentation(resizeImageForStorage(image!), 0.1)
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
    
    func resizeImageForStorage(image: UIImage) -> UIImage {
        let resizedImage = Toucan(image: image).resize(CGSize(width: 150, height: 150), fitMode: Toucan.Resize.FitMode.Crop).image
        return resizedImage
    }
    
}

