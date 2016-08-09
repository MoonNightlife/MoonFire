//
//  BarSearchViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GooglePlaces
import CoreLocation
import GeoFire
import SCLAlertView
import PagingMenuController
import Firebase
import SwiftOverlays
import ObjectMapper

class BarSearchViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Properties
    let topBarImageViewSize = CGSize(width: 240.0, height: 105.882352941176)
    let topBarImageViewScale = CGFloat(2.0)
    var handles = [UInt]()
    var pageControl = UIPageControl()
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    let locationManager = CLLocationManager()
    let barButton   = UIButton(type: UIButtonType.System) as UIButton
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    let spiritsVC = UITableViewController()
    let wineVC = UITableViewController()
    let beerVC = UITableViewController()
    var circleQuery: GFCircleQuery? = nil
    var beerSpecials = [Special2]()
    var wineSpecials = [Special2]()
    var spiritsSpecials = [Special2]()
    var beerSpecialsTemp = [Special2]()
    var wineSpecialsTemp = [Special2]()
    var spiritsSpecialsTemp = [Special2]()
    var barIDsInArea = [(barId:String,count:Int)]()
    var barIDsInAreaTemp = [(barId:String,count:Int)]()
    var readyToOrderBar = (false,0)
    var searchCount = 0
    var specialsCount = 0
    
    // MARK: - Outlets
    @IBOutlet weak var carousel: iCarousel!
    
    // MARK: - Actions
    func showOneOfTheTopBars(sender: AnyObject) {
        SwiftOverlays.showBlockingWaitOverlay()
        GMSPlacesClient().lookUpPlaceID((sender as! InvisableButton).id) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                print(error.description)
            }
            if let place = place {
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }
    
    func toggleAttendanceStatus(sender: AnyObject) {
        SwiftOverlays.showBlockingWaitOverlay()
        currentUser.child("name").observeEventType(.Value, withBlock: { (snap) in
            if let name = snap.value {
                changeAttendanceStatus((sender as! InvisableButton).id, userName: name as! String)
            }
        }) { (error) in
            print(error.description)
        }
    }

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tab controller tint set up
        tabBarController?.tabBar.tintColor = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)

        // Carousel set up
        carousel.type = .Linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.bounces = false
        carousel.pagingEnabled = true
        carousel.backgroundColor = UIColor.clearColor()

        setSearchController()
        setupSpecialsController()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        // Request location services
        checkAuthStatus(self)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        wineSpecialsTemp.removeAll()
        beerSpecialsTemp.removeAll()
        spiritsSpecialsTemp.removeAll()
        barIDsInAreaTemp.removeAll()
        
        setUpNavigation()
        
        // Rest vars to let let view know that everything has loaded
        readyToOrderBar = (false,0)
        searchCount = 0
        specialsCount = 0
        
        // Once the correct location is found, then this function will call "searchForBarsNearUser()"
        createGeoFireQueryForCurrentLocation()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "barProfile" {
            (segue.destinationViewController as! BarProfileViewController).barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - Helper functions for views
    func setSearchController() {
        // Init results controller
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.autocompleteFilter?.type = .Establishment
        
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController?.searchBar.backgroundColor = UIColor.clearColor()
        searchController?.searchBar.tintColor = UIColor.darkGrayColor()
        searchController?.searchBar.placeholder = "Search Bars"
        
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        self.navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
    }

    func configurePageControl() {
        
        self.pageControl.frame = CGRectMake(self.view.frame.size.width / 3, 270, 100, 20)
        self.pageControl.numberOfPages = barIDsInArea.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.redColor()
        self.pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        self.pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        self.view.addSubview(pageControl)
    }
    
    func setupSpecialsController() {
        // Setups the tableviews and the paging controller

        spiritsVC.title = "Spirits"
        spiritsVC.tableView.tag = 1
        spiritsVC.tableView.tintColor = UIColor.darkGrayColor()
        spiritsVC.tableView.delegate = self
        spiritsVC.tableView.dataSource = self
        
        
        wineVC.title = "Wine"
        wineVC.tableView.tag = 2
        wineVC.tableView.tintColor = UIColor.darkGrayColor()
        wineVC.tableView.delegate = self
        wineVC.tableView.dataSource = self
        
        beerVC.title = "Beer"
        beerVC.tableView.tag = 3
        beerVC.tableView.tintColor = UIColor.darkGrayColor()
        beerVC.tableView.delegate = self
        beerVC.tableView.dataSource = self
       
        
        let viewControllers = [spiritsVC,wineVC,beerVC]

        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        //pagingMenuController.view.backgroundColor = UIColor.clearColor()
   
        
        let options = PagingMenuOptions()
        options.menuHeight = 40
        options.font = UIFont(name: "Roboto-Bold", size: 12)!
        options.menuDisplayMode = .SegmentedControl
        options.defaultPage = 0
        options.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        options.selectedBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        options.textColor = UIColor.lightGrayColor()
        options.selectedTextColor = UIColor.darkGrayColor()
        options.menuItemMode = .Underline(height: 2.5, color: UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1), horizontalPadding: 5, verticalPadding: 5)
        options.selectedFont = UIFont(name: "Roboto-Bold", size: 15)!
        
        pagingMenuController.setup(viewControllers, options: options)
        
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
    
    func setSearchLocation(location: CLLocation) {
        let ne = CLLocationCoordinate2DMake(location.coordinate.latitude + 0.25, location.coordinate.longitude + 0.25)
        let sw = CLLocationCoordinate2DMake(location.coordinate.latitude - 0.25, location.coordinate.longitude - 0.25)
        resultsViewController?.autocompleteBounds = GMSCoordinateBounds(coordinate: ne, coordinate: sw)
    }
    
    // MARK: - Functions to find and order bars and specials near user
    func createGeoFireQueryForCurrentLocation() {
        // Creates and returns a query for 25 miles from the users location
        // First check to see if user has selected a location to use other than just using their gps
        currentUser.child("simLocation").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let simLocation = snap.value as? [String : AnyObject] {
                
                let simLoc = Mapper<SimLocation>().map(simLocation)
                
                if let simLoc = simLoc {
                    if let lat = simLoc.lat, let long = simLoc.long {
                        let simulatedLocation: CLLocation = CLLocation(latitude: lat, longitude: long)
                        self.setSearchLocation(simulatedLocation)
                        self.circleQuery = geoFire.queryAtLocation(simulatedLocation, withRadius: K.BarSearchViewController.BarSearchRadiusKilometers)
                    }
                }
        
            } else {
                if let userLocation = LocationService.sharedInstance.lastLocation {
                    self.setSearchLocation(userLocation)
                    self.circleQuery = geoFire.queryAtLocation(userLocation, withRadius: K.BarSearchViewController.BarSearchRadiusKilometers)
                }
            }
            self.searchForBarsNearUser()
        })
    }
    
    func searchForBarsNearUser() {
        // Find bars near current user
        let locationQuery = circleQuery
        if let query = locationQuery {
            let handle = query.observeEventType(.KeyEntered, withBlock: { (barID, location) in
                self.searchForBarInBarActivities(barID)
                self.findTheSpecialsForTheBar(barID)
                self.readyToOrderBar.1 += 1
            })
            handles.append(handle)
            query.observeReadyWithBlock({
                self.readyToOrderBar.0 = true
                // If there are no bars near user reload the table view and promt user to select location from settings
                if self.readyToOrderBar.1 == 0 {
                    self.wineSpecials.removeAll()
                    self.beerSpecials.removeAll()
                    self.spiritsSpecials.removeAll()
                    self.barIDsInArea
                        .removeAll()
                    self.spiritsVC.tableView.reloadData()
                    self.wineVC.tableView.reloadData()
                    self.beerVC.tableView.reloadData()
                    self.carousel.reloadData()
                    self.configurePageControl()
                    self.promtUser()
                }
            })
        }
    }
    
    func promtUser() {
        let alertview = SCLAlertView(appearance: K.Apperances.NormalApperance)
        alertview.addButton("Settings", action: {
            self.performSegueWithIdentifier("showSettingsFromSpecials", sender: self)
        })
        alertview.showNotice("Can't find your location", subTitle: "Without your location we can't display specials for your area. Go to settings to simulate a city")
    }
    
    func findTheSpecialsForTheBar(barID:String) {
        // Searches for specials after finding bars near user from the function "searchForBarsNearUser"
        rootRef.child("specials").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            self.specialsCount += 1
            for special in snap.children {
                let special = special as! FIRDataSnapshot
                if !(special.value is NSNull), let spec = special.value as? [String : AnyObject] {
                    
                    let specObj = Mapper<Special2>().map(spec)
                    
                    if let specialObj = specObj {
                        let currentDay = getCurrentDay()
                        
                        // Puts special under right catatgory if the special is for the current day
                        let isDayOfWeek = currentDay == specialObj.dayOfWeek
                        let isWeekDaySpecial = specialObj.dayOfWeek == Day.Weekdays
                        let isNotWeekend = (currentDay != Day.Sunday) && (currentDay != Day.Saturday)
                        if isDayOfWeek || (isWeekDaySpecial && isNotWeekend) {
                            switch specialObj.type! {
                            case .Beer:
                                self.beerSpecialsTemp.append(specialObj)
                            case .Spirits:
                                self.spiritsSpecialsTemp.append(specialObj)
                            case .Wine:
                                self.wineSpecialsTemp.append(specialObj)
                            }
                        }
                    }
                }
            }
            if self.readyToOrderBar.0 == true && self.readyToOrderBar.1 == self.specialsCount {
                if !checkIfSameSpecials(self.spiritsSpecials, group2: self.spiritsSpecialsTemp) {
                    self.spiritsSpecials = self.spiritsSpecialsTemp
                    self.spiritsVC.tableView.reloadData()
                }
                if !checkIfSameSpecials(self.wineSpecials, group2: self.wineSpecialsTemp) {
                    self.wineSpecials = self.wineSpecialsTemp
                    self.wineVC.tableView.reloadData()
                }
                if !checkIfSameSpecials(self.beerSpecials, group2: self.beerSpecialsTemp) {
                    self.beerSpecials  = self.beerSpecialsTemp
                    self.beerVC.tableView.reloadData()
                }
            }
            }) { (error) in
                print(error)
        }
    }

    func searchForBarInBarActivities(barID:String) {
        // Find out how many people are going to a certain bar based on the ID of that bar
        rootRef.child("barActivities").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.searchCount += 1
            if snap.childrenCount != 0 {
                self.barIDsInAreaTemp.append((barID,Int(snap.childrenCount)))
            }
            if self.readyToOrderBar.0 == true && self.readyToOrderBar.1 == self.searchCount {
                self.calculateTopBars()
            }
            }) { (error) in
                print(error)
        }
    }
    
    func calculateTopBars() {
        // This function sorts the global variable "barIDsInArea" and reloads the carousel
        // Orders the bars based on the users that are going there
        barIDsInAreaTemp.sortInPlace {
            return $0.count > $1.count
        }
        
        // See if the newly pulled data is different from old data
        var sameTopBars = true
        if barIDsInAreaTemp.count != barIDsInArea.count {
            sameTopBars = false
        } else {
            for i in 0..<barIDsInArea.count {
                if barIDsInArea[i].barId != barIDsInAreaTemp[i].barId {
                    sameTopBars = false
                }
                if barIDsInArea[i].count != barIDsInAreaTemp[i].count {
                    sameTopBars = false
                }
            }
        }
        
        // Only reload the table view if the data is new
        if !sameTopBars {
            barIDsInArea = barIDsInAreaTemp
            configurePageControl()
            carousel.reloadData()
        }
    }

}

// MARK: - Google bar search delegate
extension BarSearchViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    // Handle the user's selection.
    func resultsController(resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWithPlace place: GMSPlace) {
        self.performSegueWithIdentifier("barProfile", sender: place)
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: NSError){
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

// MARK: - iCarousel delegate
extension BarSearchViewController: iCarouselDelegate, iCarouselDataSource {
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int
    {
        return barIDsInArea.count
    }
    
    func carouselCurrentItemIndexDidChange(carousel: iCarousel){
        
        pageControl.currentPage = carousel.currentItemIndex
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView
    {
        var itemView: UIImageView
        var currentBarImageView: UIImageView? = nil
        var barButton2:InvisableButton? = nil
        var goButton: InvisableButton? = nil
        var titleLabel: UILabel? = nil
        //var backgroundButton: InvisableButton? = nil
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame:CGRect(x:0, y:0, width:self.view.frame.size.width, height:self.carousel.frame.size.height))
            itemView.backgroundColor = UIColor(red: 0 , green: 0, blue: 0, alpha: 0.7)
            itemView.userInteractionEnabled = true
            itemView.contentMode = .Center
            
            //bar image set up
            currentBarImageView = UIImageView()
            currentBarImageView!.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height)
            currentBarImageView?.tag = 5
            itemView.addSubview(currentBarImageView!)
            
            //base image set up
            let baseImage = UIImage(named: "translucent_bar_view.png")
            let baseImageView = UIImageView(image: baseImage)
            baseImageView.frame = CGRect(x: 0, y: itemView.frame.size.height - 60, width: itemView.frame.size.width, height: 60 )
            itemView.addSubview(baseImageView)
            
            //go button set up
            goButton = InvisableButton()
            goButton!.frame = CGRectMake(itemView.frame.size.width - 130, itemView.frame.size.height - 50, 120, 40)
            let buttonImage = UIImage(named: "Going_button.png")
            goButton!.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
            goButton!.setTitle("Go", forState: UIControlState.Normal)
            goButton!.layer.cornerRadius = 5
            goButton?.tag = 6
            goButton!.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            goButton!.titleLabel!.font =  UIFont(name: "Roboto", size: 17)
            goButton?.addTarget(self, action: #selector(BarSearchViewController.toggleAttendanceStatus(_:)), forControlEvents: .TouchUpInside)
            itemView.addSubview(goButton!)
            
            //bar title button set up
            barButton2 = InvisableButton()
            barButton2!.frame = CGRectMake(10, itemView.frame.size.height - 60, 150, 30)
            barButton2?.tag = 2
            barButton2!.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            barButton2!.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            barButton2!.titleLabel!.font =  UIFont(name: "Roboto-Bold", size: 16)
            barButton2!.addTarget(self, action: #selector(BarSearchViewController.showOneOfTheTopBars(_:)), forControlEvents: .TouchUpInside)
            itemView.addSubview(barButton2!)
            
            //people going title set up
            titleLabel = UILabel()
            titleLabel?.frame = CGRectMake(40, itemView.frame.size.height - 30, 100, 20)
            titleLabel?.tag = 3
            titleLabel?.textColor = UIColor.lightGrayColor()
            titleLabel?.font = UIFont(name: "Roboto-Bold", size: 14)
            itemView.addSubview(titleLabel!)
            
            //people going image set up
            let peopleIcon = UIImage(named: "Going_Icon")
            let peopleImageView = UIImageView(image: peopleIcon)
            peopleImageView.frame = CGRect(x: 10, y: itemView.frame.size.height - 30, width: 18, height: 18)
            itemView.addSubview(peopleImageView)
            
        }
        else
        {
            // Get a reference to the label in the recycled view
            itemView = view as! UIImageView
            goButton = itemView.viewWithTag(6) as? InvisableButton
            barButton2 = itemView.viewWithTag(2) as? InvisableButton
            titleLabel = itemView.viewWithTag(3) as? UILabel
            //backgroundButton = itemView.viewWithTag(4) as? InvisableButton
            currentBarImageView = itemView.viewWithTag(5) as? UIImageView
        }
        
        currentBarImageView?.image = nil
        // Start loading image for bar
        loadFirstPhotoForPlace(self.barIDsInArea[index].barId, imageView: currentBarImageView!, isSpecialsBarPic: false)
        
        // Adds observer to each button for each bar
        let handle = currentUser.child("currentBar").observeEventType(.Value, withBlock: { (snap) in
            // This prevents occational crashing.
            if index > self.barIDsInArea.count - 1 {
                return
            }
            if !(snap.value is NSNull), let id = snap.value as? String {
                if id == self.barIDsInArea[index].barId {
                    goButton!.setTitle("Going", forState: .Normal)
                } else {
                    goButton!.setTitle("Go", forState: .Normal)
                }
            } else {
                goButton!.setTitle("Go", forState: .Normal)
            }
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
        
        // Get simple bar information from firebase to be shown on the bar tile
        let handle2 = rootRef.child("bars").child(barIDsInArea[index].barId).observeEventType(.Value, withBlock: { (snap) in
                // This prevents occational crashing.
                if index > self.barIDsInArea.count - 1 {
                    return
                }
                if !(snap.value is NSNull), let bar = snap.value as? [String : AnyObject] {
                    
                    let barId = Context(id: snap.key)
                    let bar = Mapper<Bar2>(context: barId).map(bar)
                    
                    if let bar = bar {
                        goButton!.id = self.barIDsInArea[index].barId
                        barButton2!.id = self.barIDsInArea[index].barId
                        barButton2!.setTitle(bar.barName, forState: UIControlState.Normal)
                        titleLabel?.text = String(bar.usersGoing!)
                    }
                }
            }, withCancelBlock: { (error) in
                print(error)
            })
        handles.append(handle2)

        return itemView
    }
    
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .Spacing)
        {
            return value * 1.0
        }
        return value
    }

}

//MARK: - Specials Tableview Setup
extension BarSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView.tag {
        case 1:
            return spiritsSpecials.count
        case 2:
            return wineSpecials.count
        case 3:
            return beerSpecials.count
        default:
            return 0
        }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
       // let cellImage = UIImage(named: "BottomBar_base2.png")
        
        //heart button set up
        let heartButton = UIButton()
        heartButton.setImage(UIImage(named: "Heart_Icon2"), forState: UIControlState.Normal)
        heartButton.frame = CGRectMake(80, 55, 15, 15)
        cell.contentView.addSubview(heartButton)
        
        //Bar Image set up
        let barImage = UIImage(named: "translucent_bar_view.png")
        let newImage = resizeImage(barImage!, toTheSize: CGSizeMake(50, 50))
        cell.imageView!.image = newImage
        cell.imageView!.layer.cornerRadius = 50 / 2
        cell.imageView!.layer.masksToBounds = false
        cell.imageView!.clipsToBounds = true
        
        
        let customGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
        
       // cell.imageView?.image = cellImage
        cell.textLabel?.textColor = customBlue
        cell.detailTextLabel?.textColor = customGray
        cell.textLabel?.font = UIFont(name: "Roboto-Bold", size: 16)
        cell.detailTextLabel?.font = UIFont(name: "Roboto-Bold", size: 12)
        
        switch tableView.tag {
        case 1:
            loadFirstPhotoForPlace(spiritsSpecials[indexPath.row].barId!, imageView: cell.imageView!, isSpecialsBarPic: true)
            cell.textLabel?.text = spiritsSpecials[indexPath.row].description
            cell.detailTextLabel?.text = spiritsSpecials[indexPath.row].barName
        case 2:
            loadFirstPhotoForPlace(wineSpecials[indexPath.row].barId!, imageView: cell.imageView!, isSpecialsBarPic: true)
            cell.textLabel?.text = wineSpecials[indexPath.row].description
            cell.detailTextLabel?.text = wineSpecials[indexPath.row].barName
        case 3:
            loadFirstPhotoForPlace(beerSpecials[indexPath.row].barId!, imageView: cell.imageView!, isSpecialsBarPic: true)
            cell.textLabel?.text = beerSpecials[indexPath.row].description
            cell.detailTextLabel?.text = beerSpecials[indexPath.row].barName
        default:
            break
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var barID: String
        
        switch tableView.tag {
        case 1:
            barID = spiritsSpecials[indexPath.row].barId!
        case 2:
            barID = wineSpecials[indexPath.row].barId!
        case 3:
            barID = beerSpecials[indexPath.row].barId!
        default:
            barID = spiritsSpecials[indexPath.row].barId!
            
            
        }
        
        SwiftOverlays.showBlockingWaitOverlay()
        GMSPlacesClient().lookUpPlaceID(barID) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                print(error.description)
            }
            if let place = place {
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }
    
}


