//
//  BarProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import GeoFire
import MapKit
import CoreLocation



class BarProfileViewController: UIViewController, iCarouselDelegate, iCarouselDataSource {
    
    var barPlace:GMSPlace!
    var barRef: Firebase?
    var isGoing: Bool = false
    var oldBarRef: Firebase?
    

    let phoneNumber = UIButton()
    let website = UIButton()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    var usersForCarousel = [User]()
    var usersThere = [User]()
    var usersGoing = [User]()
    var friendsGoing = [User]()
    var specials  = [Special]()
    
    var friends = [(name:String, uid:String)]()

    // MARK: - Size Changing Variables
    var labelBorderSize = CGFloat()
    
    
    
    // MARK: - Outlets
    
    
    @IBOutlet weak var segmentControler: UISegmentedControl!
    @IBOutlet weak var peopleLabel: UILabel!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var address: UIButton!
    @IBOutlet weak var attendanceButton: UIButton!
    @IBOutlet weak var barImage: UIImageView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    
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
        setUpLabelsWithPlace()
        
        //initializing size changing variables
        labelBorderSize = self.view.frame.size.height / 22.23
        
        //set up infoView
        infoView.layer.borderColor = UIColor.whiteColor().CGColor
        infoView.layer.borderWidth = 1
        infoView.layer.cornerRadius = 5
        infoView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        //going button set up
        attendanceButton.layer.borderWidth = 1
        attendanceButton.layer.borderColor = UIColor.whiteColor().CGColor
        attendanceButton.layer.cornerRadius = 5
        
        //bar image set up
        barImage.layer.borderColor = UIColor.whiteColor().CGColor
        barImage.layer.borderWidth = 1
        barImage.layer.cornerRadius = 5
        indicator.center = CGPointMake(self.view.bounds.size.width / 2, barImage.bounds.size.height / 2)
        barImage.addSubview(indicator)
        
        
        
        //adress button set up 
        address.layer.cornerRadius = 5
        address.layer.borderColor = UIColor.whiteColor().CGColor
        address.layer.borderWidth = 1
        address.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        //carousel set up
        carousel.type = .Linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        //website set up 
        websiteButton.layer.cornerRadius = 5
        websiteButton.layer.borderWidth = 1
        websiteButton.layer.borderColor = UIColor.whiteColor().CGColor
        websiteButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        //phone button set up 
        phoneButton.layer.cornerRadius = 5
        phoneButton.layer.borderWidth = 1
        phoneButton.layer.borderColor = UIColor.whiteColor().CGColor
        phoneButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        //people / drinks label set up 
        peopleLabel.layer.borderColor = UIColor.whiteColor().CGColor
        peopleLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: peopleLabel)
        peopleLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: peopleLabel)
        peopleLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: peopleLabel)
        peopleLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: peopleLabel)
        peopleLabel.font = peopleLabel.font.fontWithSize(self.view.frame.size.height / 44.47)
        peopleLabel.textColor = UIColor.whiteColor()
        peopleLabel.text = "People There: " + String(usersThere.count)
        peopleLabel.layer.cornerRadius = 5
        
        
        
        
        
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        getArrayOfUsersGoingToBar(barPlace.placeID) { (users) in
            self.usersGoing = users
        }
        
        // Finds the friends for the users
        currentUser.childByAppendingPath("friends").queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let friends = snap {
                var newFriendList = [(name:String, uid:String)]()
                for friend in friends.children {
                    newFriendList.append((friend.key,friend.value))
                }
                self.friends = newFriendList
                
            }
        }) { (error) in
            print(error.description)
        }
        
        // This sees if we already have the bar in our records and if so displays the updated variables
        rootRef.childByAppendingPath("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                if !(bar is NSNull) {
                    
                    self.getSpecialsForBar(self.barPlace.placeID)
                    
                    self.barRef = bar.ref
                    //let usersGoing = String(bar.value["usersGoing"] as! Int)
                   // self.usersGoing.text = usersGoing
                    //let usersThere = String(bar.value["usersThere"] as! Int)
                   // self.usersThere.text = usersThere
                }
            }
            }) { (error) in
                print(error.description)
        }
        
        // This looks at the users profile and sees if he or she is attending the bar and then updating the button
        currentUser.childByAppendingPath("currentBar").observeEventType(.Value, withBlock: { (snap) in
            if(!(snap.value is NSNull)) {
            if(snap.value as! String == self.barPlace.placeID) {
                self.isGoing = true
                self.attendanceButton.titleLabel?.text = "Going"
            } else {
                self.isGoing = false
                self.attendanceButton.titleLabel?.text = "Go"
                // If there is another bar that the user was going to, store address to decreament if need be
                self.oldBarRef = rootRef.childByAppendingPath("bars").childByAppendingPath(snap.value as! String)
                }
            } else {
                self.isGoing = false
                self.attendanceButton.titleLabel?.text = "Go"
            }
            }) { (error) in
                print(error.description)
        }
    }
    
    func getSpecialsForBar(barID: String) {
        // Gets the specials for the bar and places them in an array
        
        rootRef.childByAppendingPath("specials").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                var tempSpecials = [Special]()
                for special in snap.children {
                    tempSpecials.append(Special(associatedBarId: self.barPlace.placeID, type: stringToBarSpecial(special.value["type"] as! String), description: special.value["description"] as! String, dayOfWeek: stringToDay(special.value["dayOfWeek"] as! String), barName: special.value["barName"] as! String))
                }
                self.specials = tempSpecials
            }) { (error) in
            print(error)
        }
    }
    
    // Helper function that updates the view with the bar information
    func setUpLabelsWithPlace() {
        
        self.navigationItem.title = barPlace.name
        address.setTitle(barPlace.formattedAddress, forState: UIControlState.Normal)
       // id.text = barPlace.placeID
        phoneButton.setTitle(barPlace.phoneNumber, forState: UIControlState.Normal)
        //rating.text = "\(barPlace.rating)"
       // priceLevel.text = "\(barPlace.priceLevel.rawValue)"
        if let site = barPlace.website {
            websiteButton.setTitle(site.absoluteString, forState: UIControlState.Normal)
            websiteButton.enabled = true
        } else {
            websiteButton.setTitle("No Website", forState: UIControlState.Normal)
            websiteButton.enabled = false
        }
        
        // Get bar photos
        indicator.startAnimating()
        loadFirstPhotoForPlace(barPlace.placeID)
    }
    
    // Action that changes the ammount of users going to bar as well as changes the users current bar
    @IBAction func ChangeAttendanceStatus() {
        if !isGoing {
            // If there is already a bar created updated the number of users going
            if let barRef = self.barRef {
                incrementUsersGoing(barRef)
            } else {
                createBarAndIncrementUsersGoing()
            }
            addBarToUser()
            // If the user is going to a different bar and chooses to go to the bar displayed, decreament the old bar by one
            if let oldRef = oldBarRef {
                decreamentUsersGoing(oldRef)
                // Toggle friends feed about updated barActivity
                currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    for child in snap.children {
                        if let friend: FDataSnapshot = child as? FDataSnapshot {
                            rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                        }
                    }
                    }, withCancelBlock: { (error) in
                        print(error.description)
                })
                oldBarRef = nil
            }
        } else {
            decreamentUsersGoing(self.barRef!)
            removeBarFromUsers()
        }
    }
    
    // Adds bar activity to firebase, also addeds bar ref to user as well as adding the reference to the bar activity to friends barFeeds
    func addBarToUser() {
        
        let activitiesRef = rootRef.childByAppendingPath("barActivities")
        
        // Get current time
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .FullStyle
        dateFormatter.dateStyle = .FullStyle
        let currentTime = dateFormatter.stringFromDate(date)
        print(currentTime)
        
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            // Save activity under barActivities
            let activity = ["barID": self.barPlace.placeID, "barName": self.barPlace.name, "time": currentTime, "userName": snap.value["name"] as! String]
            activitiesRef.childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(activity)
            
            // Save reference for barActivity under current user
            currentUser.childByAppendingPath("currentBar").setValue(self.barPlace.placeID)
            
            // Save reference for barActivity under each friends feed
            currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
                for child in snap.children {
                    if let friend: FDataSnapshot = child as? FDataSnapshot {
                    rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).setValue(true)
                    }
                }
                }, withCancelBlock: { (error) in
                    print(error.description)
            })
            
            }) { (error) in
                print(error.description)
        }
        
        
    }
    
    // Removes all exsitance of the bar activity
    func removeBarFromUsers() {
        
        // Remove bar reference from barActivities
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
                rootRef.childByAppendingPath("barActivities").childByAppendingPath(snap.key).removeValue()
            }) { (error) in
                print(error.description)
        }
        
        
        // Remove bar reference firom current user
        currentUser.childByAppendingPath("currentBar").removeValue()
        
        // Remove bar activity from friend's feed
        currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for child in snap.children {
                if let friend: FDataSnapshot = child as? FDataSnapshot {
                    rootRef.childByAppendingPath("users").childByAppendingPath(friend.value as! String).childByAppendingPath("barFeed").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).removeValue()
                }
            }
            }, withCancelBlock: { (error) in
                print(error.description)
        })
    }
    
    // Creates a new bar and sets init information
    func createBarAndIncrementUsersGoing() {
        // Find the radius of bar for region monitoring
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: barPlace.coordinate.latitude, longitude: barPlace.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if placemarks?.count > 1 {
                print("too many placemarks for convertion")
            } else if error == nil {
                let placemark = (placemarks![0] as CLPlacemark)
                let circularRegion = placemark.region as? CLCircularRegion
                let radius = circularRegion?.radius
                // This is where bars are created in firebase, add more moon data here
                self.barRef = rootRef.childByAppendingPath("bars").childByAppendingPath(self.barPlace.placeID)
                let initBarData = ["usersGoing" : 1, "usersThere" : 0, "radius" : radius!, "barName" : self.barPlace.name]
                self.barRef?.setValue(initBarData)
            }  else {
                print(error?.description)
            }
                
            // This creates a geoFire location
            geoFire.setLocation(CLLocation(latitude: self.barPlace.coordinate.latitude, longitude: self.barPlace.coordinate.longitude), forKey: self.barPlace.placeID) { (error) in
                if error != nil {
                    print(error.description)
    
                }
            }
        }
    }
    

    // This tracks down all the users that said they were going to a bar and returns an array of those users through a closure
    func getArrayOfUsersGoingToBar(barID: String, handler: (users:[User])->()) {
        
        rootRef.childByAppendingPath("barActivities").queryOrderedByChild("barID").queryEqualToValue(barID).observeEventType(.Value, withBlock: { (snap) in
            var counter = 0
            var users = [User]()
            for userInfo in snap.children {
                print(userInfo.key)
                rootRef.childByAppendingPath("users").childByAppendingPath(userInfo.key).observeSingleEventOfType(.Value, withBlock: { (userSnap) in
                    counter += 1
                    if !(userSnap.value is NSNull) {
                        var profilePicture: UIImage?
                        if let picString = userSnap.value["profilePicture"] as? String {
                            profilePicture = stringToUIImage(picString, defaultString: "defaultPic")
                        }
                        let user = User(name: userSnap.value["name"] as? String, userID: userSnap.key, profilePicture: profilePicture)
                        users.append(user)
                    }
                    if counter == Int(snap.childrenCount) {
                        handler(users: users)
                        self.getArrayOfFriendsFromUsersGoing(users)
                    }
                    }, withCancelBlock: { (error) in
                        print(error)
                })
            }
            }) { (error) in
                print(error)
            }
        }
    
    // This function is a helper function for "getArrayOfUsersGoingToBar" and will pick out the user's friends from an array
    func getArrayOfFriendsFromUsersGoing(users: [User]) {
        currentUser.childByAppendingPath("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            var tempUsers = [User]()
            for friend in snap.children {
                let friend = friend as! FDataSnapshot
                for user in users {
                    if user.userID! == friend.value as! String {
                        tempUsers.append(user)
                    }
                }
            }
            self.friendsGoing = tempUsers
            }) { (error) in
                print(error)
        }
    }
    
    // Google bar photo functions based on place id
    func loadFirstPhotoForPlace(placeID: String) {
        
        GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.description)")
            } else {
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(firstPhoto)
                }
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.sharedClient()
            .loadPlacePhoto(photoMetadata, constrainedToSize: barImage.bounds.size,
                            scale: self.barImage.window!.screen.scale) { (photo, error) -> Void in
                                self.indicator.stopAnimating()
                                if let error = error {
                                    // TODO: handle the error.
                                    print("Error: \(error.description)")
                                } else {
                                    self.barImage.image = photo;
                                    // TODO: handle attributes here
                                    //self.attributionTextView.attributedText = photoMetadata.attributions;
                                }
        }
    }
    
    
    //MARK: Carousel Functions
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        if segmentControler.selectedSegmentIndex == 3 {
            return specials.count
        } else {
            return usersForCarousel.count
        }
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
        
            let label = UILabel(frame:itemView.bounds)
            label.textAlignment = .Center
            label.frame = CGRectMake(0, 0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
            label.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.2)
            label.font = label.font.fontWithSize(12)
            label.textColor = UIColor.whiteColor()
            label.tag = 1
    

            
            let imageView = UIImageView()
            imageView.layer.borderColor = UIColor.whiteColor().CGColor
            imageView.layer.borderWidth = 1
            imageView.layer.masksToBounds = false
            imageView.clipsToBounds = true
            imageView.frame = CGRect(x: itemView.frame.size.width / 6, y: itemView.frame.size.height / 12, width: itemView.frame.size.width / 1.5, height: itemView.frame.size.height / 1.5)
            imageView.layer.cornerRadius = imageView.frame.size.height / 2
            

            // If segment controller is on specials then change the type of data on the carousel
            if segmentControler.selectedSegmentIndex == 3 {
                label.text = specials[index].description
                itemView.addSubview(label)
            } else {
                label.text = usersForCarousel[index].name
                imageView.image = usersForCarousel[index].profilePicture
                itemView.addSubview(label)
                itemView.addSubview(imageView)
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
    
    // MARK: - Actions
    
    @IBAction func addressButoonPressed(sender: AnyObject) {
        
        geoFire.getLocationForKey(barPlace.placeID) { (location, error) in
            if error == nil {
                if location != nil {
                    let loc = location as CLLocation
                    let regionDistance:CLLocationDistance = 10000
                    let coordinates = CLLocationCoordinate2DMake((loc.coordinate.latitude), (loc.coordinate.longitude))
                    let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
                    let options = [
                        MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: regionSpan.center),
                        MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: regionSpan.span)
                    ]
                    // TODO: Maybe reverse geocode to placmark?
                    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = self.barPlace.name
                    mapItem.openInMapsWithLaunchOptions(options)
                } else {
                    print("No location")
                }
            } else {
                print(error)
            }
        }
        
    }
    
    @IBAction func phoneButtonPressed(sender: AnyObject) {
        
        alertView("Phone Call", message: "Continue with the call?")
    }
    
    //phone number alert
    func alertView(title:String, message:String) {
        
        
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            NSLog("Calling")
            let phoneNumber = self.phoneButton.titleLabel?.text
            print(self.phoneButton.titleLabel!.text)
            self.callNumber(phoneNumber!)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            NSLog("Cancel Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the controller
        self.presentViewController(alertController, animated: true, completion: nil)
        
        
        
    }
    
    //call selected phone number
    private func callNumber(phoneNumber:String) {
        if let phoneCallURL:NSURL = NSURL(string: "tel://\(phoneNumber)") {
            let application:UIApplication = UIApplication.sharedApplication()
            
            print(application.canOpenURL(phoneCallURL))
            
            if (application.canOpenURL(phoneCallURL)) {
                application.openURL(phoneCallURL)
                print("Success")
            }
        }
    }
    
    
    @IBAction func websiteButtonPressed(sender: AnyObject) {

        let web = websiteButton.titleLabel?.text
    
        var url : NSURL
        url = (NSURL(string: web!)!)
        UIApplication.sharedApplication().openURL(url)
    }
    

    @IBAction func indexChanged(sender: UISegmentedControl) {
        
        switch segmentControler.selectedSegmentIndex {
        case 0:
            usersForCarousel = usersThere
            peopleLabel.text = "People There: " + String(usersThere.count)
        case 1:
            usersForCarousel = usersGoing
            peopleLabel.text = "People Going: " + String(usersGoing.count)
        case 2:
            usersForCarousel = friendsGoing
            peopleLabel.text = "Friends Going: " + String(friendsGoing.count)
        case 3:
            usersForCarousel.removeAll()
            peopleLabel.text = "Specials"
        default:
            break; 
        }
        carousel.reloadData()
    }
    
    
}


