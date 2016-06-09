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

enum BarSpecial: String {
    case Wine
    case Beer
    case Spirit
}

enum Day: String {
    case Monday
    case Tuesday
    case Wednesday
    case Thuresday
    case Friday
    case Saturday
    case Sunday
}

struct Special {
    var accosiatedBarId: String
    var type: BarSpecial
    var description: String
    var dayOfWeek: Day
    var specialID: String
}

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
    var specials = [Special]()
    
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
    
    func setupSpecialsController() {
        
        //let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
        let spiritsVC = UITableViewController()
        spiritsVC.title = "Spirits"
        spiritsVC.view.backgroundColor = UIColor.greenColor()
//        spiritsVC.tableView.delegate = self
//        spiritsVC.tableView.dataSource = self
        let wineVC = UITableViewController()
        wineVC.title = "Wine"
        wineVC.view.backgroundColor = UIColor.brownColor()
//        wineVC.tableView.delegate = self
//        wineVC.tableView.dataSource = self
        let beerVC = UITableViewController()
        beerVC.title = "Beer"
        beerVC.view.backgroundColor = UIColor.purpleColor()
//        beerVC.tableView.delegate = self
//        beerVC.tableView.dataSource = self
        let viewControllers = [spiritsVC,wineVC,beerVC]
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        
        let options = PagingMenuOptions()
        options.menuHeight = 40
        options.menuDisplayMode = .SegmentedControl
        options.defaultPage = 1
        options.backgroundColor = UIColor.lightGrayColor()
        options.textColor = UIColor.whiteColor()
        options.selectedBackgroundColor = UIColor.whiteColor()
        options.selectedTextColor = UIColor.blueColor()
        pagingMenuController.setup(viewControllers, options: options)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Populates the top bar section of view
        barIDsInArea.removeAll()
        readyToOrderBar = (false,0)
        searchCount = 0
        searchForBarsNearUser()
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
                self.readyToOrderBar.1 += 1
            })
            query.observeReadyWithBlock({
                self.readyToOrderBar.0 = true
                query.removeAllObservers()
            })
        }
    }
    
    func findTheSpecialsForTheBar(barID:String) {
        rootRef.childByAppendingPath("bars").childByAppendingPath("barID/specials").observeEventType(.Value, withBlock: { (snap) in
            for special in snap.children {
                //let special = Special(accosiatedBarId: barID, type: BarSpecial(rawValue: "Wine")!, description: <#T##String#>, dayOfWeek: <#T##Day#>, specialID: <#T##String#>)
            }
            }) { (error) in
                print(error)
        }
    }
    
    func stringToBarSpecial(name:String) {
        
    }
    
    // Find out how many people are going to a certain bar based on the ID of that bar
    func searchForBarInBarActivities(barID:String) {
        rootRef.childByAppendingPath("barActivities").queryOrderedByChild("barID").queryEqualToValue(barID).observeEventType(.Value, withBlock: { (snap) in
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
            
            
            let barLabel = UILabel()
            barLabel.frame = CGRectMake(0,0, itemView.frame.size.width - 20, itemView.frame.size.width / 11.07)
            barLabel.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 2 )
            barLabel.backgroundColor = UIColor.clearColor()
            barLabel.layer.addBorder(UIRectEdge.Left, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
            barLabel.layer.addBorder(UIRectEdge.Bottom, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
            barLabel.layer.addBorder(UIRectEdge.Right, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
            barLabel.layer.addBorder(UIRectEdge.Top, color: UIColor.whiteColor(), thickness: 1, length: labelBorderSize, label: barLabel)
            barLabel.layer.cornerRadius = 5
            barLabel.font = barLabel.font.fontWithSize(fontSize)
            barLabel.textColor = UIColor.whiteColor()
            barLabel.text = barIDsInArea[index].barId
            barLabel.textAlignment = NSTextAlignment.Center
            itemView.addSubview(barLabel)
            
            
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

}

//extension BarSearchViewController: UITableViewDelegate, UITableViewDataSource {
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 0
//    }
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 30
//    }
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        <#code#>
//    }
//}
