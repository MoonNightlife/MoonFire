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

class BarSearchViewController: UIViewController {
    
    // MARK: - Properties

    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    let locationManager = CLLocationManager()
    let barButton   = UIButton(type: UIButtonType.System) as UIButton
    var barIDsInArea = [(barId:String,count:Int)]()
    
    // Carousel array
    var items: [Int] = []
    override func awakeFromNib()
    {
        super.awakeFromNib()
        for i in 0...2
        {
            items.append(i)
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var carousel: iCarousel!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    // MARK: - Helper functions for top bar views
    
    // Creates and returns a query for 25 miles from the users location
    func createGeoFireQueryForCurrentLocation() -> GFCircleQuery? {
        if let userLocation = locationManager.location {
            return geoFire.queryAtLocation(userLocation, withRadius: 40.2336)
        } else {
            return nil
        }
    }
    
    // Find bars near current user
    func searchForBarsNearUser() {
        let locationQuery = createGeoFireQueryForCurrentLocation()
        if let query = locationQuery {
            query.observeEventType(.KeyEntered, withBlock: { (barID, location) in
                self.searchForBarInBarActivities(barID)
            })
            query.observeReadyWithBlock({ 
                self.calculateTopBars()
                query.removeAllObservers()
            })
        }
    }
    
    // Find out how many people are going to a certain bar based on the ID of that bar
    func searchForBarInBarActivities(barID:String) {
        rootRef.childByAppendingPath("barActivities").queryOrderedByChild("barID").observeEventType(.Value, withBlock: { (snap) in
            if snap.childrenCount == 0 {
                self.barIDsInArea.append((barID,Int(snap.childrenCount)))
            }
            }) { (error) in
                print(error)
        }
    }
    // This function sorts the global variable "barIDsInArea" and sets the carousel array accordingly
    func calculateTopBars() {
        barIDsInArea.sortInPlace {
            return $0.count > $1.count
        }
        print(barIDsInArea)
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
        return items.count
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
            
            if (index == 0){
                let goingToImage = "avenu-dallas.jpg"
                let image1 = UIImage(named: goingToImage)
                let imageView1 = UIImageView(image: image1!)
                imageView1.layer.borderColor = UIColor.whiteColor().CGColor
                imageView1.layer.borderWidth = 1
                imageView1.frame = CGRect(x: 0, y: 0, width: itemView.frame.size.width, height: itemView.frame.size.height / 1.7)
                imageView1.layer.cornerRadius = 5
                itemView.addSubview(imageView1)
                
                barButton.frame = CGRectMake(itemView.frame.size.height / 8, itemView.frame.size.height / 1.5, 220, 30)
                barButton.center = CGPoint(x: itemView.frame.midX, y: itemView.frame.size.height / 1.3)
                barButton.backgroundColor = UIColor.clearColor()
                barButton.layer.borderWidth = 1
                barButton.layer.borderColor = UIColor.whiteColor().CGColor
                barButton.layer.cornerRadius = 5
                barButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                itemView.addSubview(barButton)
                
            }
            
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
        label.text = "\(items[index])"
        
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

