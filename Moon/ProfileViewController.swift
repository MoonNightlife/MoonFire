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
import SwiftOverlays
import GeoFire
import SCLAlertView
import GooglePlaces


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
        
        viewSetUp()
        
        checkForFriendRequest()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Search for photos from flickr
        //searchForPhotos()
        
        // Find the location of the user and find the closest city
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        cityImageIndicator.center = cityCoverImage.center
        cityImageIndicator.startAnimating()
        if locationManager.location == nil {
            locationManager.startUpdatingLocation()
        } else {
            queryForNearbyCities(locationManager.location!)
        }
        
        getUsersProfileInformation()
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
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

    func getUsersProfileInformation() {
        
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.getUsersCurrentBar()
            
            //show the one depending on their profile settings (EVAN HAS A SMALL WEINER)
            
            //male symbol
            let male: Character = "\u{2642}"
            
            //female symbole 
           // let female: Character = "\u{2640}"
            
            //username
            //let username = snap.value!["username"] as? String
      
            self.navigationItem.title = (snap.value!["name"] as? String)! + " " + String(male)
            
            //**** EVAN (Hi)*** The bioLabel has to have this image set when there is no bio
            self.bioLabel.backgroundColor = UIColor(patternImage: UIImage(named: "bio_line.png")!)
            //self.bioLabel.text = snap.value!["bio"] as? String ?? "Update Bio In Settings"
            
            
            self.drinkLabel.text = (snap.value!["favoriteDrink"] as? String ?? "")
            self.birthdayLabel.text = snap.value!["age"] as? String
            self.genderLabel.text = snap.value! ["gender"] as? String
            

            // Sets the profile picture
            self.indicator.stopAnimating()
            if let base64EncodedString = snap.value!["profilePicture"] as? String {
                self.profilePicture.image = stringToUIImage(base64EncodedString, defaultString: "defaultPic")
            } else {
                //TODO: added picture giving instructions to click on photo
                self.profilePicture.image = UIImage(contentsOfFile: "defaultPic")
            }
            
        }) { (error) in
            print(error.description)
        }

    }

    func viewSetUp() {
        
        // Sets a circular profile pic
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true
        indicator.center = profilePicture.center
        profilePicture.addSubview(indicator)
        indicator.startAnimating()
        
        // Adds tap gesture
        tapPic.addTarget(self, action: #selector(ProfileViewController.tappedProfilePic))
        profilePicture.addGestureRecognizer(tapPic)
        profilePicture.userInteractionEnabled = true
        
        
        // Sets the navigation control colors
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        //self.navigationItem.backBarButtonItem?.setBackgroundImage(UIImage(named:"Back_Arrow"), forState: UIControlState.Normal, barMetrics: .Default)
        //self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        //Top View set up
        let header = "Title_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
        //scroll view set up
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()

        
        cityText.text = "Unknown City"
        
        createTestCity()
    }
    
    
    // MARK: - Friend Request Button
    
    func checkForFriendRequest() {
        // Checks for friends request so a badge can be added to the friend button on the top left of the profile
        let handle = rootRef.child("friendRequest").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
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
            print(error.description)
        }
        self.handles.append(handle)
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
    
    // Gets the current bar and its accociated information to be displayed. If there is no current bar for the user then it hides that carousel
    func getUsersCurrentBar() {
        let handle = rootRef.child("barActivities").child(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.numberOfCarousels = 2
                   
                    self.barButton.setTitle(snap.value!["barName"] as? String, forState: .Normal)
                    
                    // Get the number of users going
                    rootRef.child("bars").child(snap.value!["barID"] as! String).observeSingleEventOfType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull) {
                            let usersGoing = snap.value!["usersGoing"] as? Int ?? 0
                            self.currentPeopleGoing.text = "People Going: " + String(usersGoing)
                        }
                    })
        
                    self.currentBarID = snap.value!["barID"] as? String
                    if self.currentBarID != nil {
                        loadFirstPhotoForPlace(self.currentBarID!, imageView: self.currentBarImageView, searchIndicator: self.currentBarIndicator)
                    } else {
                        // If there is no current bar then stop the indicator and hide carousel
                        self.currentBarIndicator.stopAnimating()
                    }
                } else {
                    self.numberOfCarousels = 1
                                   }
        }) { (error) in
                print(error)
        }
        self.handles.append(handle)
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
        currentUser.child("profilePicture").setValue(base64String)
    }

    
}




