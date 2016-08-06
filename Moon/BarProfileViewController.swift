//
//  BarProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GooglePlaces
import Firebase
import GeoFire
import MapKit
import CoreLocation
import SwiftOverlays
import PagingMenuController
import ObjectMapper

class BarProfileViewController: UIViewController {
    
    // MARK: - Properties
    var handles = [UInt]()
    var barPlace:GMSPlace!
    var barRef: FIRDatabaseReference?
    var isGoing: Bool = false
    var oldBarRef: FIRDatabaseReference?
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    var isFavoriteBar = false
    let phoneNumber = UIButton()
    let website = UIButton()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    var usersForCarousel = [SimpleUser]()
    var usersThere = [SimpleUser]()
    var usersGoing = [SimpleUser]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }
    var friendsGoing = [SimpleUser]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }
    var specials  = [Special2]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }
    var usersGoingCount = "0"
    var usersThereCount = "0"
    var friends = [(name:String, uid:String)]()
    var icons = [UIImage]()
    var labelBorderSize = CGFloat()
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segmentControler: ADVSegmentedControl!
    @IBOutlet weak var peopleLabel: UILabel!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var address: UIButton!
    @IBOutlet weak var attendanceButton: UIButton!
    @IBOutlet weak var barImage: UIImageView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var favoriteThisBarButton: UIButton!
    @IBOutlet weak var heartImageView: UIImageView!
    
    // MARK: - Action
    @IBAction func favoriteTheBarButton(sender: AnyObject) {
        if isFavoriteBar {
            currentUser.child("favoriteBarId").removeValue()
        } else {
            currentUser.child("favoriteBarId").setValue(barPlace?.placeID)
        }
    }
    
    @IBAction func ChangeAttendanceStatus() {
        // Action that changes the ammount of users going to bar as well as changes the users current bar
        SwiftOverlays.showBlockingWaitOverlay()
        currentUser.child("name").observeEventType(.Value, withBlock: { (snap) in
            if let name = snap.value {
                changeAttendanceStatus(self.barPlace.placeID, userName: name as! String)
            }
        }) { (error) in
            print(error.description)
        }
    }
    
    func barUserClicked(sender: AnyObject) {
        performSegueWithIdentifier("showProfileFromBar", sender: sender.id)
    }
    
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
    
    func alertView(title:String, message:String) {
        // Phone number alert
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
    
    func callNumber(phoneNumber:String) {
        //call selected phone numberv
        let phoneURL = "tel://" + phoneNumber
        UIApplication.sharedApplication().openURL(NSURL(string: phoneURL)!)
        
    }
    
    @IBAction func websiteButtonPressed(sender: AnyObject) {
        
        let web = websiteButton.titleLabel?.text
        
        var url : NSURL
        url = (NSURL(string: web!)!)
        UIApplication.sharedApplication().openURL(url)
    }
    
    func segmentValueChanged(sender: AnyObject?){
        
        if segmentControler.selectedIndex == 0 {
            
            usersForCarousel = usersGoing
            peopleLabel.text = usersGoingCount + " going"
            
        }else if segmentControler.selectedIndex == 1{
            
            usersForCarousel = friendsGoing
            peopleLabel.text =  String(friendsGoing.count) + " friends going"
            
        }else{
            usersForCarousel.removeAll()
            // TODO: Hide friend icon
            peopleLabel.text = "Specials"
        }
        
        carousel.reloadData()
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLabelsWithPlace()
        setUpView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpNavigation()
        findUsersGoingToBar()
        checkIfBarExistAndSetBarInfo()
        checkForBarAttendanceStatus()
        checkIfUsersFavoriteBarIsCurrentBar()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfileFromBar" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = sender as! String
        }
    }

    // MARK: - Helper functions for view
    func setUpView() {
        
        //bar image set up
        indicator.center = CGPointMake(self.view.bounds.size.width / 2, barImage.bounds.size.height / 2)
        barImage.addSubview(indicator)
        
        //adress button set up
        address.layer.cornerRadius = 5
        address.layer.borderColor = UIColor.whiteColor().CGColor
        address.layer.borderWidth = 1
        
        //carousel set up
        carousel.type = .Linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        
        //website set up
        websiteButton.layer.cornerRadius = 5
        websiteButton.layer.borderWidth = 1
        websiteButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        //phone button set up
        phoneButton.layer.cornerRadius = 5
        phoneButton.layer.borderWidth = 1
        phoneButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        //people label
        peopleLabel.text = String(usersThere.count) +  " going"
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        //array of special icons
        icons.append(UIImage(named: "martini_icon.png")!)
        icons.append(UIImage(named: "beer_icon.png")!)
        icons.append(UIImage(named: "wine_icon.png")!)
        
        
        //segment set up
        segmentControler.items = ["People Going", "Friends Going", "Specials"]
        //segmentControler.font = UIFont(name: "Roboto-Bold", size: 10)
        segmentControler.selectedLabelColor = UIColor.darkGrayColor()
        segmentControler.borderColor = UIColor.clearColor()
        segmentControler.backgroundColor = UIColor.clearColor()
        segmentControler.selectedIndex = 0
        segmentControler.unselectedLabelColor = UIColor.lightGrayColor()
        segmentControler.thumbColor = UIColor.clearColor()
        segmentControler.addTarget(self, action: #selector(BarProfileViewController.segmentValueChanged(_:)), forControlEvents: .ValueChanged)
        
        //scroll view set up
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 750)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
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
    
    func findUsersGoingToBar() {
        // This function will only display the users that have privacy turned off or if privacy is turned off 
        //then it checks to see if the user is your friend
        getArrayOfUsersGoingToBar(barPlace.placeID) { (users) in
            var usersTemp = [SimpleUser]()
            var friendCounter = 0
            var counter = 0
            for user in users {
                if user.privacy == false || user.userID! == currentUser.key {
                    counter += 1
                    usersTemp.append(user)
                } else {
                    friendCounter += 1
                    checkIfFriendBy(user.userID!, handler: { (isFriend) in
                        if isFriend == true {
                            usersTemp.append(user)
                        }
                        if friendCounter == users.count - counter  {
                            self.usersGoing = usersTemp
                        }
                    })
                }
            }
            if friendCounter == 0 {
                self.usersGoing = usersTemp
            }
        }

    }
    
    func checkIfBarExistAndSetBarInfo() {
        // This sees if we already have the bar in our records and if so displays the updated variables
        let handle = rootRef.child("bars").queryOrderedByKey().queryEqualToValue(barPlace.placeID).observeEventType(.Value, withBlock: { (snap) in
            for bar in snap.children {
                if !(bar is NSNull) {
                    
                    self.getSpecialsForBar(self.barPlace.placeID)
                    self.barRef = bar.ref
                    print(bar.value["usersGoing"] as? Int)
                    self.usersGoingCount = String(bar.value["usersGoing"] as! Int)
                    //self.usersThereCount = String(bar.value["usersThere"] as! Int)
                    
                }
            }
        }) { (error) in
            print(error.description)
        }
        handles.append(handle)
    }
    
    func checkForBarAttendanceStatus() {
        // This looks at the users profile and sees if he or she is attending the bar and then updating the button
        let handle2 = currentUser.child("currentBar").observeEventType(.Value, withBlock: { (snap) in
            if(!(snap.value is NSNull)) {
                if(snap.value as! String == self.barPlace.placeID) {
                    self.isGoing = true
                    self.attendanceButton.setTitle("Going", forState: UIControlState.Normal)
                } else {
                    self.isGoing = false
                    self.attendanceButton.setTitle("Go", forState: UIControlState.Normal)
                    // If there is another bar that the user was going to, store address to decreament if need be
                    self.oldBarRef = rootRef.child("bars").child(snap.value as! String)
                }
            } else {
                self.isGoing = false
                self.attendanceButton.setTitle("Go", forState: UIControlState.Normal)
            }
        }) { (error) in
            print(error.description)
        }
        handles.append(handle2)
    }
    
    func getSpecialsForBar(barID: String) {
        // Gets the specials for the bar and places them in an array
        rootRef.child("specials").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                var tempSpecials = [Special2]()
                for special in snap.children {
                    let special = special as! FIRDataSnapshot
                    if !(special.value is NSNull), let spec = special.value as? [String : AnyObject] {
                        
                        let specObj = Mapper<Special2>().map(spec)
                        
                        if let specialObj = specObj {
                            let currentDay = getCurrentDay()
                            
                            let isDayOfWeek = currentDay == specialObj.dayOfWeek
                            let isWeekDaySpecial = specialObj.dayOfWeek == Day.Weekdays
                            let isNotWeekend = (currentDay != Day.Sunday) && (currentDay != Day.Saturday)
                            if isDayOfWeek || (isWeekDaySpecial && isNotWeekend) {
                                tempSpecials.append(specialObj)
                            }
                        }
                    }
                    
                }
                self.specials = tempSpecials
            
            }) { (error) in
                print(error.description)
        }
    }
    
    func setUpLabelsWithPlace() {
        
        // Get bar photos
        indicator.startAnimating()
        loadFirstPhotoForPlace(barPlace.placeID, imageView: barImage, indicator: indicator, isSpecialsBarPic: false)
        
        // Helper function that updates the view with the bar information
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
    
    }

    func checkIfUsersFavoriteBarIsCurrentBar() {
        let handle = currentUser.child("favoriteBarId").observeEventType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let barId = snap.value as? String {
                if barId == self.barPlace.placeID {
                    self.isFavoriteBar = true
                    self.favoriteThisBarButton.setTitle("Favorite Bar", forState: .Normal)
                    self.heartImageView.image = UIImage(named: "Heart_Icon_Red.png")
                    return
                }
            }
            self.isFavoriteBar = false
            self.favoriteThisBarButton.setTitle("Favorite This Bar", forState: .Normal)
            self.heartImageView.image = UIImage(named: "Heart_Icon2.png")
            }) { (error) in
                print(error.description)
        }
        handles.append(handle)
    }
    
    func getArrayOfUsersGoingToBar(barID: String, handler: (users:[SimpleUser])->()) {
        // This tracks down all the users that said they were going to a bar and returns an array of those users through a closure
        let handle = rootRef.child("barActivities").queryOrderedByChild("barID").queryEqualToValue(barID).observeEventType(.Value, withBlock: { (snap) in
            var counter = 0
            var users = [SimpleUser]()
            for userInfo in snap.children {
                rootRef.child("users").child(userInfo.key).child("privacy").observeSingleEventOfType(.Value, withBlock: { (snapPrivacy) in
                    counter += 1
                    if !(snapPrivacy.value is NSNull), let privacy = snapPrivacy.value {
                        let user = SimpleUser(name: userInfo.value!["userName"] as? String, userID: userInfo.key, privacy: privacy as? Bool)
                        users.append(user)
                    }
                    // Once all the users have been found return array of user through closure
                    if counter == Int(snap.childrenCount) {
                        handler(users: users)
                        self.getArrayOfFriendsFromUsersGoing(users)
                    }
                    }, withCancelBlock: { (error) in
                        showAppleAlertViewWithText(error.description, presentingVC: self)
                })
            }
            }) { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
            }
        handles.append(handle)
    }
    
    func getArrayOfFriendsFromUsersGoing(users: [SimpleUser]) {
        // This function is a helper function for "getArrayOfUsersGoingToBar" and will pick out the user's friends from an array and set it to a global var
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            var tempUsers = [SimpleUser]()
            for friend in snap.children {
                let friend = friend as! FIRDataSnapshot
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
    
}

extension BarProfileViewController: iCarouselDelegate, iCarouselDataSource {
    
    // MARK: - Carousel functions
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        if segmentControler.selectedIndex == 2 {
            return specials.count
        } else {
            return usersForCarousel.count
        }
        
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView
    {
        var itemView: UIImageView
        var imageView2: UIImageView? = nil
        var imageView: UIImageView? = nil
        var label: UILabel? = nil
        var activityIndicator: UIActivityIndicatorView? = nil
        var invisablebutton: InvisableButton? = nil
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            
            //setting up the item view for the carousel
            itemView = UIImageView(frame:CGRect(x:0, y:0, width: 100, height: carousel.frame.size.height - 10))
            itemView.userInteractionEnabled = true
            itemView.contentMode = .Center
            
            label = UILabel(frame:itemView.bounds)
            label!.textAlignment = .Center
            label!.frame = CGRectMake(0, 0, itemView.frame.size.width - 20, 30)
            label!.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
            label!.font = label!.font.fontWithSize(12)
            label!.lineBreakMode = .ByWordWrapping
            label!.numberOfLines = 0
            label!.textColor = UIColor.lightGrayColor()
            label!.tag = 3
            
            //item view background image set up
            let backgroundImage = UIImage(named: "Profile_base_bar.png")
            let backgrounImageView = UIImageView(image: backgroundImage)
            backgrounImageView.frame = CGRectMake(0, 0, 100, carousel.frame.size.height - 10)
            itemView.addSubview(backgrounImageView)
            itemView.sendSubviewToBack(backgrounImageView)
            
            
            
            // If segment controller is on specials then change the type of data on the carousel
            if segmentControler.selectedIndex == 2 {
                
                //specials image
                imageView = UIImageView()
                imageView!.frame = CGRect(x: itemView.frame.size.width / 4, y: itemView.frame.size.height / 8, width: itemView.frame.size.width / 2, height: itemView.frame.size.height / 2)
                imageView!.tag = 1
                itemView.addSubview(imageView!)
                itemView.addSubview(label!)
                
                
                
            } else {
                
                //profile picture
                imageView2 = UIImageView()
                imageView2!.layer.masksToBounds = false
                imageView2!.clipsToBounds = true
                imageView2!.frame = CGRect(x: itemView.frame.size.width / 5, y: itemView.frame.size.height / 14, width: itemView.frame.size.width / 1.7, height: itemView.frame.size.width / 1.7)
                imageView2!.tag = 2
                imageView2!.layer.cornerRadius = imageView2!.frame.size.width / 2
                
                // Indicator for profile pictures
                activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
                activityIndicator!.center = CGPointMake(imageView2!.bounds.size.width / 2, imageView2!.bounds.size.height / 2)
                imageView2?.addSubview(activityIndicator!)
                
                
                //button that takes you to profile
                invisablebutton = InvisableButton()
                invisablebutton!.tintColor = UIColor.clearColor()
                invisablebutton!.frame = itemView.frame
                invisablebutton!.addTarget(self, action: #selector(BarProfileViewController.barUserClicked(_:)), forControlEvents: .TouchUpInside)
                invisablebutton?.tag = 4
                
                itemView.addSubview(invisablebutton!)
                itemView.addSubview(label!)
                itemView.addSubview(imageView2!)
            }
            
        } else {
            //get a reference to the label in the recycled view
            itemView = view as! UIImageView
            imageView = itemView.viewWithTag(1) as? UIImageView
            imageView2 = itemView.viewWithTag(2) as? UIImageView
            label = itemView.viewWithTag(3) as? UILabel
            invisablebutton = itemView.viewWithTag(4) as? InvisableButton
            
            
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        
        if segmentControler.selectedIndex == 2 {
            if  specials[index].type == BarSpecial.Wine {
                
                imageView!.image = icons[2]
                
            } else if specials[index].type == BarSpecial.Beer {
                
                imageView!.image = icons[1]
                
            } else if specials[index].type == BarSpecial.Spirits {
                
                imageView!.image = icons[0]
            }
            
            label!.text = specials[index].description
        } else {
            label!.text = usersForCarousel[index].name
            activityIndicator!.startAnimating()
            getProfilePictureForUserId(usersForCarousel[index].userID!, imageView: imageView2!)
            invisablebutton!.id = usersForCarousel[index].userID!
        }
        
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

class InvisableButton: UIButton {
    var id: String = ""
}


