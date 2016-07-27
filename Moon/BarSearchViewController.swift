//
//  BarSearchViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/22/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import GeoFire
import SCLAlertView
import PagingMenuController
import Firebase
import SwiftOverlays

class BarSearchViewController: UIViewController {
    

    
    // MARK: - Properties
    
    let topBarImageViewSize = CGSize(width: 240.0, height: 105.882352941176)
    let topBarImageViewScale = CGFloat(2.0)
    
    var handles = [UInt]()

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
    let currentBarIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    var circleQuery: GFCircleQuery? = nil
    
    // For the specials' tableviews
    // Main
    var beerSpecials = [Special]()
    var wineSpecials = [Special]()
    var spiritsSpecials = [Special]()
    // Temp
    var beerSpecialsTemp = [Special]()
    var wineSpecialsTemp = [Special]()
    var spiritsSpecialsTemp = [Special]()
    
    // For the carousel
    // Main
    var barIDsInArea = [(barId:String,count:Int)]()
    var barImages = [UIImage]()
    // Temp
    var barIDsInAreaTemp = [(barId:String,count:Int)]()
    var barImagesTemp = [UIImage]()
    


    
    // These vars are used to know when to update the carousel view
    var readyToOrderBar = (false,0)
    var searchCount = 0
    var specialsCount = 0
    var imageCount = 0
    
    // MARK: - Outlets
    
    @IBOutlet weak var carousel: iCarousel!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        labelBorderSize = self.view.frame.size.height / 22.23
        buttonHeight = self.view.frame.size.height / 33.35
        fontSize = self.view.frame.size.height / 47.64

        
        // Init results controller
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.autocompleteFilter?.type = .Establishment

        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
            
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        self.navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // Carousel set up
        carousel.type = .Linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        setupSpecialsController()
        
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        
    }
    
    // Setups the tableviews and the paging controller
    func setupSpecialsController() {
        
        //let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
        spiritsVC.title = "Spirits"
        spiritsVC.tableView.tag = 1
        spiritsVC.tableView.tintColor = UIColor.darkGrayColor()
        spiritsVC.tableView.delegate = self
        spiritsVC.tableView.dataSource = self
        spiritsVC.tableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        
        
        
        wineVC.title = "Wine"
        wineVC.tableView.tag = 2
        wineVC.tableView.tintColor = UIColor.darkGrayColor()
        wineVC.tableView.delegate = self
        wineVC.tableView.dataSource = self
        wineVC.tableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        
        beerVC.title = "Beer"
        beerVC.tableView.tag = 3
        beerVC.tableView.tintColor = UIColor.darkGrayColor()
        beerVC.tableView.delegate = self
        beerVC.tableView.dataSource = self
        beerVC.tableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        
        let viewControllers = [spiritsVC,wineVC,beerVC]

        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.view.backgroundColor = UIColor.clearColor()
       // pagingMenuController.menuView.
        
        
        let options = PagingMenuOptions()
        options.menuHeight = 40
        options.menuDisplayMode = .SegmentedControl
        options.defaultPage = 1
        options.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        options.selectedBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        options.textColor = UIColor.darkGrayColor()
        options.selectedTextColor = UIColor.blackColor()

        
        
        pagingMenuController.setup(viewControllers, options: options)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        wineSpecialsTemp.removeAll()
        beerSpecialsTemp.removeAll()
        spiritsSpecialsTemp.removeAll()
        barIDsInAreaTemp.removeAll()
        barImagesTemp.removeAll()

//        self.spiritsVC.tableView.reloadData()
//        self.wineVC.tableView.reloadData()
//        self.beerVC.tableView.reloadData()
//        self.carousel.reloadData()
        
        readyToOrderBar = (false,0)
        searchCount = 0
        specialsCount = 0
        imageCount = 0
        
        // Once the correct location is found, then this function will call "searchForBarsNearUser()"
        createGeoFireQueryForCurrentLocation()
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    func setSearchLocation(location: CLLocation) {
        let ne = CLLocationCoordinate2DMake(location.coordinate.latitude + 0.25, location.coordinate.longitude + 0.25)
        let sw = CLLocationCoordinate2DMake(location.coordinate.latitude - 0.25, location.coordinate.longitude - 0.25)
        resultsViewController?.autocompleteBounds = GMSCoordinateBounds(coordinate: ne, coordinate: sw)
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
    
    // MARK: - Functions to find and order bars near user
    
    // Creates and returns a query for 25 miles from the users location
    func createGeoFireQueryForCurrentLocation() {
        // First check to see if user has selected a location to use other than just using their gps
        
        currentUser.child("simLocation").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                let long = snap.value!["long"] as? Double
                let lat = snap.value!["lat"] as? Double
                if long != nil && lat != nil {
                    let simulatedLocation:CLLocation = CLLocation(latitude: lat!, longitude: long!)
                    self.setSearchLocation(simulatedLocation)
                    self.circleQuery = geoFire.queryAtLocation(simulatedLocation, withRadius: 40.2336)
                }
            } else {
                if let userLocation = self.locationManager.location {
                    self.setSearchLocation(userLocation)
                    self.circleQuery = geoFire.queryAtLocation(userLocation, withRadius: 40.2336)
                } else {
                    let alertview = SCLAlertView()
                    alertview.addButton("Settings", action: {
                       self.performSegueWithIdentifier("showSettingsFromSpecials", sender: self)
                    })
                    alertview.showError("Can't find your location", subTitle: "Without your location we can't display specials for your area")
                }
            }
            self.searchForBarsNearUser()
        })
    }
    
    // Find bars near current user
    func searchForBarsNearUser() {
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
            })
        }
    }
    
    // Searches for specials after finding bars near user from the function "searchForBarsNearUser"
    func findTheSpecialsForTheBar(barID:String) {
        
        rootRef.child("specials").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            self.specialsCount += 1
            for special in snap.children {
                if !(special is NSNull) {
                    let type = stringToBarSpecial(special.value["type"] as! String)
                    let description = special.value["description"] as? String
                    let dayOfWeek = stringToDay(special.value["dayOfWeek"] as! String)
                    let name = special.value["barName"] as? String
                    
                    let specialObj = Special(associatedBarId: barID, type: type, description: description!, dayOfWeek:dayOfWeek, barName: name!)
                    
                    let currentDay = getCurrentDay()
                    
                    let isDayOfWeek = currentDay == specialObj.dayOfWeek
                    let isWeekDaySpecial = specialObj.dayOfWeek == Day.Weekdays
                    let isNotWeekend = (currentDay != Day.Sunday) && (currentDay != Day.Saturday)
                    if isDayOfWeek || (isWeekDaySpecial && isNotWeekend) {
                        switch specialObj.type {
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
            print(self.spiritsSpecials)
            
            if self.readyToOrderBar.0 == true && self.readyToOrderBar.1 == self.specialsCount {
                self.spiritsSpecials = self.spiritsSpecialsTemp
                self.wineSpecials = self.wineSpecialsTemp
                self.beerSpecials = self.beerSpecialsTemp
                self.spiritsVC.tableView.reloadData()
                self.wineVC.tableView.reloadData()
                self.beerVC.tableView.reloadData()
            }
            }) { (error) in
                print(error)
        }
    }
    

    
    // Find out how many people are going to a certain bar based on the ID of that bar
    func searchForBarInBarActivities(barID:String) {
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
    
    // This function sorts the global variable "barIDsInArea" and reloads the carousel
    func calculateTopBars() {
        
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
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView
    {
        var itemView: UIImageView
        var currentBarImageView: UIImageView? = nil
        var indicator: UIActivityIndicatorView? = nil
        var barButton2:InvisableButton? = nil
        var titleLabel: UILabel? = nil
        var backgroundButton: InvisableButton? = nil
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame:CGRect(x:0, y:0, width:240, height:180))
            //itemView.image = UIImage(named: "page.png")
            itemView.backgroundColor = UIColor(red: 0 , green: 0, blue: 0, alpha: 0.5)
            itemView.layer.cornerRadius = 5
            itemView.layer.borderWidth = 1
            itemView.userInteractionEnabled = true
            itemView.layer.borderColor = UIColor.whiteColor().CGColor
            itemView.contentMode = .Center
            
            currentBarImageView = UIImageView()
            currentBarImageView!.layer.borderColor = UIColor.whiteColor().CGColor
            currentBarImageView!.layer.borderWidth = 1
            currentBarImageView!.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
            currentBarImageView!.layer.cornerRadius = 5
            currentBarImageView?.tag = 5
            itemView.addSubview(currentBarImageView!)
            
            // Indicator for top bar picture
            indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            indicator!.center = CGPointMake(currentBarImageView!.frame.size.width / 2, currentBarImageView!.frame.size.height / 2)
            indicator?.tag = 1
            currentBarImageView!.addSubview(indicator!)
            
            backgroundButton = InvisableButton()
            backgroundButton?.frame = itemView.frame
            backgroundButton?.center = itemView.center
            backgroundButton?.backgroundColor = UIColor.clearColor()
            backgroundButton?.tag = 4
            backgroundButton?.addTarget(self, action: #selector(BarSearchViewController.showOneOfTheTopBars(_:)), forControlEvents: .TouchUpInside)
            itemView.addSubview(backgroundButton!)
            
            barButton2 = InvisableButton()
            barButton2!.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, itemView.frame.size.width - 20, self.buttonHeight)
            barButton2!.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.45)
            barButton2!.backgroundColor = UIColor.clearColor()
            barButton2!.layer.borderWidth = 1
            barButton2!.layer.borderColor = UIColor.whiteColor().CGColor
            barButton2!.layer.cornerRadius = 5
            barButton2?.tag = 2
            barButton2!.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            barButton2!.titleLabel!.font =  UIFont(name: "Helvetica Neue", size: self.fontSize)
            barButton2!.addTarget(self, action: #selector(BarSearchViewController.showOneOfTheTopBars(_:)), forControlEvents: .TouchUpInside)
            itemView.addSubview(barButton2!)
            titleLabel = self.createGaboLabelWithTitle(CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07), center: CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.15))
            titleLabel?.tag = 3
            itemView.addSubview(titleLabel!)
            
        }
        else
        {
            // Get a reference to the label in the recycled view
            itemView = view as! UIImageView
            
            indicator = itemView.viewWithTag(1) as? UIActivityIndicatorView
            barButton2 = itemView.viewWithTag(2) as? InvisableButton
            titleLabel = itemView.viewWithTag(3) as? UILabel
            backgroundButton = itemView.viewWithTag(4) as? InvisableButton
            currentBarImageView = itemView.viewWithTag(5) as? UIImageView
        }
        
        currentBarImageView?.image = nil
        indicator?.startAnimating()
        // Start loading image for bar
        loadFirstPhotoForPlace(self.barIDsInArea[index].barId, imageView: currentBarImageView!, indicator: indicator!)
        
        // Get simple bar information from firebase to be shown on the bar tile
        rootRef.child("bars").child(barIDsInArea[index].barId).observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                
                let usersGoing = snap.value!["usersGoing"] as? Int
                let barName = snap.value!["barName"] as? String
    
                if let name = barName {
                    backgroundButton?.id = self.barIDsInArea[index].barId
                    barButton2!.id = self.barIDsInArea[index].barId
                    barButton2!.setTitle(name, forState: UIControlState.Normal)
                }
                if let title = usersGoing {
                    let going = "Going: " + String(title)
                    titleLabel!.text = going
                }
                
            }
            }, withCancelBlock: { (error) in
                print(error)
        })

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

    
    // Helper function that creates label with title as input parameter
    func createGaboLabelWithTitle(frame: CGRect, center: CGPoint) -> UILabel {
        let barLabel = UILabel()
        barLabel.frame = frame
        barLabel.center = center
        barLabel.backgroundColor = UIColor.clearColor()
        barLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
        barLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
        barLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
        barLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
        barLabel.layer.cornerRadius = 5
        barLabel.font = barLabel.font.fontWithSize(fontSize)
        barLabel.textColor = UIColor.whiteColor()
        barLabel.textAlignment = NSTextAlignment.Center
        return barLabel
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
        return 45
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        
        switch tableView.tag {
        case 1:
            cell.textLabel?.text = spiritsSpecials[indexPath.row].description
            cell.detailTextLabel?.text = spiritsSpecials[indexPath.row].barName
        case 2:
            cell.textLabel?.text = wineSpecials[indexPath.row].description
            cell.detailTextLabel?.text = wineSpecials[indexPath.row].barName
        case 3:
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
            barID = spiritsSpecials[indexPath.row].associatedBarId
        case 2:
            barID = wineSpecials[indexPath.row].associatedBarId
        case 3:
            barID = beerSpecials[indexPath.row].associatedBarId
        default:
            barID = spiritsSpecials[indexPath.row].associatedBarId
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


