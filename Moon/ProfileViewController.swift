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
import ObjectMapper


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FlickrPhotoDownloadDelegate {

    // MARK: - Properties
    var handles = [UInt]()
    let flickrService = FlickrServices()
    let tapPic = UITapGestureRecognizer()
    var surroundingCities = [City2]()
    var currentCity: City2?
    var foundAllCities = (false, 0)
    var counter = 0
    let placeClient = GMSPlacesClient()
    var currentBarID:String? = nil
    var favoriteBarId: String? = nil
    let currentPeopleGoing = UILabel()
    var circleQuery: GFCircleQuery? = nil
    var currentBarUsersHandle: UInt?
    var favoriteBarUsersHandle: UInt?
    
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
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goingToCurrentBarButton.hidden = true
        
        getProfilePictureForUserId(currentUser.key, imageView: profilePicture)
        
        flickrService.delegate = self
        
        viewSetUp()
        
        // Get the closest city information
        if LocationService.sharedInstance.lastLocation == nil {
            // "queryForNearbyCities" is called after location is updated in "didUpdateLocations"
            checkAuthStatus(self)
        } else {
            queryForNearbyCities(LocationService.sharedInstance.lastLocation!, promtUser: true)
        }

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        getUsersProfileInformation()
        checkForFriendRequest()
        setUpNavigation()
        
        if let location = LocationService.sharedInstance.lastLocation {
            queryForNearbyCities(location, promtUser: false)
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove all the observers
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
        // These observers are handled differently beacuse it is changing all the time
        if let hand = currentBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        if let hand = favoriteBarUsersHandle {
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
            if !(snap.value is NSNull),let userProfileInfo = snap.value as? [String : AnyObject] {
                
                let userId = Context(id: snap.key)
                let user = Mapper<User2>(context: userId).map(userProfileInfo)
                
                if let user = user {
                    self.drinkLabel.text = user.favoriteDrink
                    self.birthdayLabel.text = user.age
                    
                    self.navigationItem.title = (user.name ?? "") + " " + (genderSymbolFromGender(user.gender) ?? "")
                    
                    if let bio = user.bio {
                        self.bioLabel.backgroundColor = nil
                        self.bioLabel.text = bio
                    } else {
                        self.bioLabel.text = nil
                        self.bioLabel.backgroundColor = UIColor(patternImage: UIImage(named: "bio_line.png")!)
                    }
                    
                    // Every time a users current bar this code will be executed to go grab the current bar information
                    if let currentBarId = user.currentBarId {
                        getActivityForUserId(FIRAuth.auth()!.currentUser!.uid, handle: { (activity) in
                            if seeIfShouldDisplayBarActivity(activity) {
                                // If the current bar is the same from the last current bar it looked at then dont do anything
                                if currentBarId != self.currentBarID {
                                    self.goingToCurrentBarButton.hidden = false
                                    self.currentBarUsersGoing.hidden = false
                                    self.currentBarID = currentBarId
                                    self.observeCurrentBarWithId(currentBarId)
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
                            self.favoriteBarId = favoriteBarId
                            self.observeFavoriteBarWithId(favoriteBarId)
                        }
                    } else {
                        self.favoriteBarImageView.image = UIImage(named: "Default_Image.png")
                        self.favoriteBarButton.setTitle("No Favorite Bar", forState: .Normal)
                        self.favoriteBarId = nil
                        self.favoriteBarUsersGoingLabel.text = nil

                    }
                }
            }

        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }
    
    func removeCurrentBarImages() {
        self.currentBarImageView.image = UIImage(named: "Default_Image.png")
        self.barButton.setTitle("No Plans", forState: .Normal)
        self.goingToCurrentBarButton.hidden = true
        if let handle = self.currentBarUsersHandle {
            rootRef.removeObserverWithHandle(handle)
            self.currentBarUsersHandle = nil
        }
        self.currentBarUsersGoing.hidden = true
        self.currentBarID = nil
    }
    
    
    func observeCurrentBarWithId(barId: String) {
      
        // First load image since the bar image won't be changing between method calls
        loadFirstPhotoForPlace(barId, imageView: self.currentBarImageView, isSpecialsBarPic: false)
        
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
        //TODO: setup real activity indicator
        loadFirstPhotoForPlace(barId, imageView: favoriteBarImageView, isSpecialsBarPic: false)
        
        // Removes the old observer for users going
        if let hand = favoriteBarUsersHandle {
            rootRef.removeObserverWithHandle(hand)
        }
        
        // Adds a new observer for the new BarId and set the labels
        let handle = rootRef.child("bars").child(barId).observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let bar = snap.value {
                
                let barId = Context(id: snap.key)
                let bar = Mapper<Bar2>(context: barId).map(bar)
                
                if let bar = bar {
                    getNumberOfUsersGoingBasedOffBarValidBarActivities(bar.barId!, handler: { (numOfUsers) in
                        print(numOfUsers)
                        self.favoriteBarUsersGoingLabel.text = String(numOfUsers)
                    })
                    
                    self.favoriteBarButton.setTitle(bar.barName, forState: .Normal)
                }
             
            }
        }) { (error) in
            print(error.description)
        }
        
        // Sets global handle for the current BarId
        favoriteBarUsersHandle = handle
    }

    func viewSetUp() {
        
        cityCoverImage.frame.size.height = self.view.frame.size.height / 5.02
        
        name.frame.size.height = self.view.frame.size.height / 31.76
        name.frame.size.width = self.view.frame.size.height / 3.93
        
        // Sets a circular profile pic
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        profilePicture.backgroundColor = UIColor.clearColor()
        
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
    

    
    func setUpNavigation(){
        
        // Navigation controller set up
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationItem.backBarButtonItem?.title = ""
        
        // Top View set up
        let header = "Title_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
    }
    
    // MARK: - City locater
    func queryForNearbyCities(location: CLLocation, promtUser: Bool) {
        counter = 0
        foundAllCities = (false,0)
        self.surroundingCities.removeAll()
        // Get user simulated location if choosen, but if there isnt one then use location services on the phone
        currentUser.child("simLocation").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let city = snap.value as? [String : AnyObject] {
                
                let city = Mapper<City2>().map(city)
        
                if let city = city {
                    if let long = city.long, let lat = city.lat {
                        let simulatedLocation = CLLocation(latitude: lat, longitude: long)
                        print(simulatedLocation)
                        self.circleQuery = geoFireCity.queryAtLocation(simulatedLocation, withRadius: K.Profile.CitySearchRadiusKilometers)
                    }
                }
                
            } else {
                self.circleQuery = geoFireCity.queryAtLocation(location, withRadius: K.Profile.CitySearchRadiusKilometers)
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
                    getCityPictureForCityId("-KKFSTnyQqwgQzFmEjcj" , imageView: self.cityCoverImage)
                    self.cityText.text = "Unknown City"
                    let cityData = ["name":"Unknown City","cityId":"-KKFSTnyQqwgQzFmEjcj"]
                    currentUser.child("cityData").setValue(cityData)

                    if promtUser {
                        self.promptUser()
                    }
                }
            }
        })
    }
    
    func promptUser() {
        let alertview = SCLAlertView(appearance: K.Apperances.NormalApperance)
        alertview.addButton("Settings", action: {
            self.performSegueWithIdentifier("showSettingsFromProfile", sender: self)
        })
        alertview.showNotice("Not in supported city", subTitle: "Moon is currently not avaible in your city, but you can select a city from user settings")
    }
    
    func getCityInformation(id: String) {
        rootRef.child("cities").child(id).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            if !(snap.value is NSNull), let city = snap.value {
                
                let cityId = Context(id: snap.key)
                let city = Mapper<City2>(context: cityId).map(city)
                
                self.counter += 1
                self.surroundingCities.append(city!)
                if self.foundAllCities.1 == self.counter && self.foundAllCities.0 == true {
                    
                    self.currentCity = self.surroundingCities.first
                    self.cityText.text = self.currentCity!.name
                    
                    self.cityCoverImage.startAnimating()
                    getCityPictureForCityId(self.currentCity!.cityId! , imageView: self.cityCoverImage)
                    let cityData = ["name":self.currentCity!.name!,"cityId":self.currentCity!.cityId!]
                    currentUser.child("cityData").setValue(cityData)
                }
            }
            }) { (error) in
                print(error)
        }
    }
    
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
     
    }
    
    func resizeImageForStorage(image: UIImage) -> UIImage {
        let resizedImage = Toucan(image: image).resize(CGSize(width: 150, height: 150), fitMode: Toucan.Resize.FitMode.Crop).image
        return resizedImage
    }
    
    // MARK:- Flickr photo download
    func finishedDownloading(photos: [Photo]) {
        cityCoverImage.hnk_setImageFromURL(photos[0].imageURL)
    }
    
    func searchForPhotos() {
        flickrService.makeServiceCall("Dallas Skyline")
    }
    
}

