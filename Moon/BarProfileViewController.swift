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
import RxSwift

class BarProfileViewController: UIViewController {
    
    // MARK: - Services
    private let barService: BarService = FirebaseBarService()
    private let userService: UserService = FirebaseUserService()
    private let pushNotificationService: PushNotificationService = BatchService()
    private let barActivitiesService: BarActivitiesService = FirebaseBarActivitiesService()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    var barID: String!
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    let phoneNumber = UIButton()
    let website = UIButton()
    var usersForCarousel = [BarActivity2]()
    
    var usersGoing = [BarActivity2]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }
    var friendsGoing = [BarActivity2]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }
    var specials  = [Special2]() {
        didSet {
            segmentValueChanged(segmentControler)
        }
    }

    var icons = [UIImage]()
    var labelBorderSize = CGFloat()
    
    // MARK: - Outlets
    @IBOutlet weak var barRatingNumber: UIButton!
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

    @IBOutlet weak var heartImageButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    
    // MARK: - Action
    @IBAction func favoriteTheBarButton(sender: AnyObject) {
        
        userService.getUserInformationFor(UserType: UserType.SignedInUser)
            .flatMap { (result) -> Observable<BackendResponse> in
                switch result {
                case .Success(let user):
                    if user.userProfile?.favoriteBarId == self.barID {
                        self.favoriteThisBarButton.setTitle("Favorite This Bar", forState: .Normal)
                        self.heartImageButton.setImage(UIImage(named: "Heart_Icon2.png"), forState: .Normal)
                        return self.userService.updateFavoriteBar("")
                    } else {
                        self.favoriteThisBarButton.setTitle("Favorite Bar", forState: .Normal)
                        self.heartImageButton.setImage(UIImage(named: "Heart_Icon_Red.png"), forState: .Normal)
                        return self.userService.updateFavoriteBar(self.barID)
                    }
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            }
            .subscribeNext { (response) in
                switch response {
                case .Success:
                    print("favorite bar updated")
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func ChangeAttendanceStatus() {
        
        let barInfoObservable = barService.getBarInformationFor(BarID: barID)
        let userInfoObservable = userService.getUserSnapshotForUserType(UserType: UserType.SignedInUser)
        
        barActivitiesService.getBarActivityFor(UserType: UserType.SignedInUser)
            .flatMap({ (result) -> Observable<BackendResponse> in
                switch result {
                case .Success(let activity):
                    if activity?.barId != self.barID {
                        return self.barActivitiesService.createAndSaveBarActivityForSignedInUser(barInfoObservable, userInfoObservable: userInfoObservable)
                    } else {
                        return self.barActivitiesService.deleteBarActivityForSignedInUser()
                    }
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
            .flatMap({ (response) -> Observable<BackendResult<BarActivity2?>> in
                switch response {
                case .Success:
                    //TODO: Send push notification that friend is going out, the function below isnt the right one, but the parameters in function call should be used with the new call
                    print("bar activity saved or removed")
                //sendPush(false, badgeNum: 1, groupId: "Friends Going Out", title: "Moon", body: "Your friend " + userName + " is going out to " + barName, customIds: filteredFriends, deviceToken: "nil")
                    return self.barActivitiesService.getBarActivityFor(UserType: UserType.SignedInUser)
                case .Failure(let error):
                    return Observable.just(BackendResult.Failure(error: error))
                }

            })
            .subscribeNext { (activity) in
                switch activity {
                case .Success(let activity):
                    if activity?.barId == self.barID {
                        self.attendanceButton.setTitle("Going", forState: UIControlState.Normal)
                    } else {
                        self.attendanceButton.setTitle("Go", forState: UIControlState.Normal)
                    }
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
                
            
        
    }
    
    func barUserClicked(sender: AnyObject) {
        performSegueWithIdentifier("showProfileFromBar", sender: sender.id)
    }
    
    @IBAction func addressButoonPressed(sender: AnyObject) {
        
        geoFire.getLocationForKey(barID) { (location, error) in
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
                    //TODO: Find a way to add the name of bar
                    //mapItem.name = self.barPlace.name
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
            if let phoneNumber = self.phoneButton.titleLabel?.text {
                //print(phoneNumber)
                self.callNumber(phoneNumber)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            //NSLog("Cancel Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the controller
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func callNumber(phoneNumber:String) {
        //call selected phone numberv
        if let phoneURL = NSURL(string: "tel://" + phoneNumber.stringByReplacingOccurrencesOfString(" ", withString: "").stringByReplacingOccurrencesOfString("-", withString: "").stringByReplacingOccurrencesOfString("+", withString: "")) {
            UIApplication.sharedApplication().openURL(phoneURL)
        }
    }
    
    @IBAction func websiteButtonPressed(sender: AnyObject) {
        
        let web = websiteButton.titleLabel?.text
        
        if let url = NSURL(string: web!) {
            UIApplication.sharedApplication().openURL(url)
        }
        
    }
    
    func segmentValueChanged(sender: AnyObject?){
        
        if segmentControler.selectedIndex == 0 {
            
            usersForCarousel = usersGoing
            peopleLabel.text = String(usersGoing.count) + " going"
            
        } else if segmentControler.selectedIndex == 1 {
            
            usersForCarousel = friendsGoing
            peopleLabel.text =  String(friendsGoing.count) + " friends going"
            
        } else {
            usersForCarousel.removeAll()
            // TODO: Hide friend icon
            peopleLabel.text = "Specials"
        }
        
        carousel.reloadData()
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        
        barService.getBarInformationFor(BarID: self.barID)
            .subscribeNext { (result) in
                switch result {
                case .Success(let barInfo):
                    self.setUpLabelsWithBar(barInfo)
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
        barService.getSpecialsFor(BarID: self.barID)
            .subscribeNext { (result) in
                switch result {
                case .Success(let specials):
                    self.specials = specials
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpNavigation()
        getBarActivitiesForCurrentBar()
        checkForBarAttendanceStatus()
        checkIfUsersFavoriteBarIsCurrentBar()
        
        //scroll view set up
       // scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 750)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()

        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width:self.view.frame.size.width, height:750)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "showProfileFromBar" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = sender as! String
        }
    }

    // MARK: - Helper functions for view
    func setUpView() {
        
        //address button set up
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
        websiteButton.enabled = true
        
        //phone button set up
        phoneButton.layer.cornerRadius = 5
        phoneButton.layer.borderWidth = 1
        phoneButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        //people label
        peopleLabel.text = String(usersGoing.count) +  " going"
        
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
    
    func getBarActivitiesForCurrentBar() {
        
        barActivitiesService.getBarActivitiesForBar(barID)
            .subscribeNext { (result) in
                switch result {
                case .Success(let activities):
                    self.usersGoing = activities
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
    func checkForBarAttendanceStatus() {
        
        barActivitiesService.getBarActivityFor(UserType: UserType.SignedInUser)
            .map({ (result) -> BarActivity2? in
                switch result {
                case .Success(let activity):
                    return activity
                case .Failure(let error):
                    print(error)
                    return nil
                }
            })
            .subscribeNext { (activity) in
                if activity?.barId == self.barID {
                    self.attendanceButton.setTitle("Going", forState: UIControlState.Normal)
                } else {
                    self.attendanceButton.setTitle("Go", forState: UIControlState.Normal)
                }
            }
            .addDisposableTo(disposeBag)

    }
    
    func setUpLabelsWithBar(barInfo: BarInfo) {
        
        // Get bar photos
        //TODO: Use google places to get picture id
        //loadFirstPhotoForPlace(barPlace.placeID, imageView: barImage, isSpecialsBarPic: false)
        
        // Helper function that updates the view with the bar information
        self.navigationItem.title = barInfo.barName
        //TODO: Figure out a rating system for the bars
        //self.barRatingNumber.setTitle(String(barPlace.rating), forState: .Normal)
        address.setTitle(barInfo.address, forState: UIControlState.Normal)
       // id.text = barPlace.placeID
        phoneButton.setTitle(barInfo.phoneNumber, forState: UIControlState.Normal)
        //rating.text = "\(barPlace.rating)"
       // priceLevel.text = "\(barPlace.priceLevel.rawValue)"
        if let site = barInfo.website {
            websiteButton.setTitle(site, forState: UIControlState.Normal)
            websiteButton.enabled = true
        } else {
            websiteButton.setTitle("No Website", forState: UIControlState.Normal)
            websiteButton.enabled = false
        }
    
    }

    func checkIfUsersFavoriteBarIsCurrentBar() {
        
        userService.getUserInformationFor(UserType: UserType.SignedInUser)
            .subscribeNext { (result) in
                switch result {
                case .Success(let user):
                    if user.userProfile?.favoriteBarId == self.barID {
                        self.favoriteThisBarButton.setTitle("Favorite Bar", forState: .Normal)
                        self.heartImageButton.setImage(UIImage(named: "Heart_Icon_Red.png"), forState: .Normal)
                    } else {
                        self.favoriteThisBarButton.setTitle("Favorite This Bar", forState: .Normal)
                        self.heartImageButton.setImage(UIImage(named: "Heart_Icon2.png"), forState: .Normal)
                    }
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
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
                imageView2!.image = UIImage(named: "translucent_bar_view.png")
                imageView2!.layer.masksToBounds = false
                imageView2!.clipsToBounds = true
                imageView2!.frame = CGRect(x: itemView.frame.size.width / 5, y: itemView.frame.size.height / 14, width: itemView.frame.size.width / 1.7, height: itemView.frame.size.width / 1.7)
                imageView2!.tag = 2
                imageView2!.layer.cornerRadius = imageView2!.frame.size.width / 2
                
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
            label!.text = usersForCarousel[index].userName
            getProfilePictureForUserId(usersForCarousel[index].userId!, imageView: imageView2!)
            
            if let button = invisablebutton, let id = usersForCarousel[index].userId {
                button.id = id
            }
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


