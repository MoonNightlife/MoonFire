//
//  FeaturedBarsTableViewController.swift
//  Moon
//
//  Created by Gabriel I Leyva Merino on 8/10/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import SCLAlertView
import ObjectMapper
import CoreLocation
import GeoFire
import Firebase
import SwiftOverlays
import GooglePlaces

class FeaturedBarsTableViewController: UITableViewController {
    
    // MARK: - Properties
    var foundAllCities = (false, 0)
    var counter = 0
    var surroundingCities = [City2]()
    var handles = [UInt]()
    var featAct = [FeaturedBarActivity]()
    
    func setUpView() {
        
        // Background set up
        let goingToImage = "Moons_View_Background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
        
        //tableView set up
        self.tableView.rowHeight = 219
        self.tableView.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = UIColor.whiteColor()
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None

    }
    
    func setUpNavigation(){
        
        //navigation controller set up
        self.navigationItem.title = "Featured Events"
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        //Top View set up
        let header = "Header_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
    }
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        
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
        
        // Load tableview with friend request from users
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
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "barProfileFromFeatured" {
            (segue.destinationViewController as! BarProfileViewController).barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - City locater
    func queryForNearbyCities(location: CLLocation, promtUser: Bool) {
        var circleQuery: GFCircleQuery? = nil
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
                        circleQuery = geoFireCity.queryAtLocation(simulatedLocation, withRadius: K.Profile.CitySearchRadiusKilometers)
                    }
                }
                
            } else {
                circleQuery = geoFireCity.queryAtLocation(location, withRadius: K.Profile.CitySearchRadiusKilometers)
            }
            let handle = circleQuery!.observeEventType(.KeyEntered) { (key, location) in
                self.foundAllCities.1 += 1
                self.getCityInformation(key)
            }
            self.handles.append(handle)
            circleQuery!.observeReadyWithBlock {
                self.foundAllCities.0 = true
                // If there is no simulated location and we can't find a city near the user then prompt them with a choice
                // to go to settings and pick a city named location
                if self.foundAllCities.1 == 0 {
                    // No city found
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
            self.performSegueWithIdentifier("showSettingsFromFeatured", sender: self)
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
                    if let city = city {
                        self.navigationItem.title = "Featured Events For \(city.name!)"
                        self.getFeaturesForCityId(city.cityId!)
                    }
                    
                }
            }
        }) { (error) in
            print(error)
        }
    }
    
    
    
    func getFeaturesForCityId(cityId: String) {
        let handle = rootRef.child("featuredActivities").queryOrderedByChild("cityId").queryEqualToValue(cityId).observeEventType(.Value, withBlock: { (snap) in
            var featActTemp = [FeaturedBarActivity]()
            for featuredActivity in snap.children {
                let featuredActivity = featuredActivity as! FIRDataSnapshot
                if !(featuredActivity.value is NSNull), let featureAct = featuredActivity.value as? [String : AnyObject] {
                    
                    let faId = Context(id: featuredActivity.key)
                    let featuredAct = Mapper<FeaturedBarActivity>(context: faId).map(featureAct)
                    
                    if let featuredAct = featuredAct {
                        featActTemp.append(featuredAct)
                    }
                    
                }
            }
            if !checkIfSameFeaturedBarActivities(featActTemp, group2: self.featAct) {
                self.featAct = featActTemp
                self.tableView.reloadData()
            }
            }) { (error) in
                print(error.description)
        }
        handles.append(handle)
    }
    
    // MARK: - Actions
    func showBarWithId(barId: String) {
        SwiftOverlays.showBlockingWaitOverlay()
        GMSPlacesClient().lookUpPlaceID(barId) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                print(error.description)
            }
            if let place = place {
                self.performSegueWithIdentifier("barProfileFromFeatured", sender: place)
            }
        }
    }

    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return featAct.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("FeatureCell", forIndexPath: indexPath) as! FeaturedTableViewCell
        cell.name.setTitle(featAct[indexPath.row].name, forState: .Normal)
        cell.descriptionLabel.text = featAct[indexPath.row].description
        cell.date.text = featAct[indexPath.row].date
        cell.time.text = featAct[indexPath.row].time
        if let barId = featAct[indexPath.row].barId {
            loadFirstPhotoForPlace(barId, imageView: cell.backgroundImage, isSpecialsBarPic: false)
        } else {
            //TODO: look for image path of uploaded picture
        }
        
    
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        showBarWithId(featAct[indexPath.row].barId!)
    }


}
