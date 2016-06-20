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

class BarSearchViewController: UIViewController {
    

    
    // MARK: - Properties

    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    let locationManager = CLLocationManager()
    let barButton   = UIButton(type: UIButtonType.System) as UIButton
    var barIDsInArea = [(barId:String,count:Int)]()
    var labelBorderSize = CGFloat()
    var fontSize = CGFloat()
    var buttonHeight = CGFloat()
    var beerSpecials = [Special]()
    var wineSpecials = [Special]()
    var spiritsSpecials = [Special]()
    let spiritsVC = UITableViewController()
    let wineVC = UITableViewController()
    let beerVC = UITableViewController()
    
    // These vars are used to know when to update the carousel view
    var readyToOrderBar = (false,0)
    var searchCount = 0
    
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
        carousel.type = .CoverFlow
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.clearColor()
        
        setupSpecialsController()
        
    }
    
    // Setups the tableviews and the paging controller
    func setupSpecialsController() {
        
        //let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
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
        
        let options = PagingMenuOptions()
        options.menuHeight = 40
        options.menuDisplayMode = .SegmentedControl
        options.defaultPage = 1
        options.backgroundColor = UIColor.whiteColor()
        options.textColor = UIColor.blueColor()
        options.selectedTextColor = UIColor.blueColor()
        pagingMenuController.setup(viewControllers, options: options)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Populates the top bar section of view
        barIDsInArea.removeAll()
        wineSpecials.removeAll()
        beerSpecials.removeAll()
        spiritsSpecials.removeAll()
        readyToOrderBar = (false,0)
        searchCount = 0
        searchForBarsNearUser()
        
        // User for testing
//            let testSpecial = Special(associatedBarId: "ChIJ_aufJEr3rIkRq39pQcK1oiU", type: .Beer , description: "Miller Lite Sale", dayOfWeek: .Tuesday, barName: "Barstools & Dinettes Etc")
//            addSpecial("ChIJ_aufJEr3rIkRq39pQcK1oiU", special: testSpecial)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Use to set limit results to current area
        if let userLocation = locationManager.location {
            let ne = CLLocationCoordinate2DMake(userLocation.coordinate.latitude + 0.25, userLocation.coordinate.longitude + 0.25)
            let sw = CLLocationCoordinate2DMake(userLocation.coordinate.latitude - 0.25, userLocation.coordinate.longitude - 0.25)
            resultsViewController?.autocompleteBounds = GMSCoordinateBounds(coordinate: ne, coordinate: sw)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "barProfile" {
            (segue.destinationViewController as! BarProfileViewController).barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - Functions to find and order bars near user
    
    // Creates and returns a query for 25 miles from the users location
    func createGeoFireQueryForCurrentLocation() -> GFCircleQuery? {
        if let userLocation = locationManager.location {
            return geoFire.queryAtLocation(userLocation, withRadius: 40.2336)
        } else {
            SCLAlertView().showError("Can't find your location", subTitle: "Without your location we can't display specials for your area")
            return nil
        }
    }
    
    // Find bars near current user
    func searchForBarsNearUser() {
        let locationQuery = createGeoFireQueryForCurrentLocation()
        if let query = locationQuery {
            query.observeEventType(.KeyEntered, withBlock: { (barID, location) in
                self.searchForBarInBarActivities(barID)
                self.findTheSpecialsForTheBar(barID)
                self.readyToOrderBar.1 += 1
            })
            query.observeReadyWithBlock({
                self.readyToOrderBar.0 = true
                query.removeAllObservers()
            })
        }
    }
    
    // Searches for specials after finder bars near user from previous function
    func findTheSpecialsForTheBar(barID:String) {
        rootRef.childByAppendingPath("specials").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
            for special in snap.children {
                if !(special is NSNull) {
                    print(special)
                    let type = stringToBarSpecial(special.value["type"] as! String)
                    let description = special.value["description"] as? String
                    let dayOfWeek = stringToDay(special.value["dayOfWeek"] as! String)
                    let name = special.value["barName"] as? String
                    
                    
                    let specialObj = Special(associatedBarId: barID, type: type, description: description!, dayOfWeek:dayOfWeek, barName: name!)
                    
                    switch specialObj.type {
                    case .Beer:
                        self.beerSpecials.append(specialObj)
                    case .Spirits:
                        self.spiritsSpecials.append(specialObj)
                    case .Wine:
                        self.wineSpecials.append(specialObj)
                    }
                }
            }
            if self.readyToOrderBar.0 == true && self.readyToOrderBar.1 == self.searchCount {
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
        rootRef.childByAppendingPath("barActivities").queryOrderedByChild("barID").queryEqualToValue(barID).observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.searchCount += 1
            if snap.childrenCount != 0 {
                self.barIDsInArea.append((barID,Int(snap.childrenCount)))
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
        barIDsInArea.sortInPlace {
            return $0.count > $1.count
        }
        carousel.reloadData()
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
        var label: UILabel
        var itemView: UIImageView
        
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
            itemView.layer.borderColor = UIColor.whiteColor().CGColor
            itemView.contentMode = .Center
            
            // Get simple bar information from firebase to be shown on the bar tile
            rootRef.childByAppendingPath("bars").childByAppendingPath(barIDsInArea[index].barId).observeEventType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull) {
                        let usersGoing = snap.value["usersGoing"] as? Int
                        let usersThere = snap.value["usersThere"] as? Int
                        let barName = snap.value["barName"] as? String
                        if let name = barName {
                            itemView.addSubview(self.createGaboLabelWithTitle(name, frame: CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07), center: CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 5)))
                        }
                        if let title = usersGoing {
                            itemView.addSubview(self.createGaboLabelWithTitle(String(title), frame: CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07), center: CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 2)))
                        }
                        if let title = usersThere {
                            itemView.addSubview(self.createGaboLabelWithTitle(String(title), frame: CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07), center: CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.2)))
                        }
                        
                    }
                }, withCancelBlock: { (error) in
                    print(error)
            })
            
            label = UILabel(frame:itemView.bounds)
            label.backgroundColor = UIColor.clearColor()
            label.textAlignment = .Center
            label.font = label.font.fontWithSize(50)
            label.tag = 1
            //itemView.addSubview(label)
        }
        else
        {
            //get a reference to the label in the recycled view
            itemView = view as! UIImageView;
            label = itemView.viewWithTag(1) as! UILabel!
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "\(barIDsInArea[index])"
        
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
    
    // Helper function that creates label with title as input parameter
    func createGaboLabelWithTitle(title: String, frame: CGRect, center: CGPoint) -> UILabel {
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
        barLabel.text = title
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
        print(tableView.tag)
        
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
}
