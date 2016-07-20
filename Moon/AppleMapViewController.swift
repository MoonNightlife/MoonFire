//
//  AppleMapViewController.swift
//  Moon
//
//  Created by Evan Noble on 5/7/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GeoFire
import Firebase
import GoogleMaps
import SCLAlertView

class AppleMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var handles = [UInt]()

    // MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    var regionQuery: GFRegionQuery?
    var circleQuery: GFCircleQuery?
    let locationManager = CLLocationManager()
    let placeClient = GMSPlacesClient()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        checkAuthStatus()
    }
    
    // Zooms to user location when the map is viewed
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let location = locationManager.location {
            zoomToUserLocation(location)
        } else {
            SCLAlertView().showError("Can't find your location", subTitle: "Without your location we can't display your location on the map")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showBarProfile" {
            (segue.destinationViewController as! BarProfileViewController).barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - Actions
    // User has a button to go back to his location if he or she gets lost on the map
    @IBAction func goToCurrentLocation(sender: AnyObject) {
        if let location = locationManager.location {
            zoomToUserLocation(location)
        } else {
            SCLAlertView().showError("Can't find your location", subTitle: "Without your location we can't display your location on the map")
        }

    }
    
    // MARK: - Mapview delegate methods
    // Creates the annotation with the correct image for how many users say they are going
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        let reuseIdentifier = "pin"
        var v = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if v == nil {
            v = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            v!.canShowCallout = true
            
            let btn = UIButton(type: .DetailDisclosure)
            v?.rightCalloutAccessoryView = btn
        }
        else {
            v!.annotation = annotation
        }
        
        let customPointAnnotation = annotation as! BarAnnotation
        
        //image set up for pin on map
        v!.image = UIImage(named:customPointAnnotation.imageName)
        v!.alpha = 1
        v!.frame.size.height = 25
        v!.frame.size.width = 25
      
        return v
    }
    
    // Looks up the bar that was selected on the map, and displays the bar profile
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let placeID = view.annotation?.subtitle
        
        placeClient.lookUpPlaceID(placeID!!) { (place, error) in
            if let error = error {
                print(error.description)
            }
            
            if let place = place {
                self.performSegueWithIdentifier("showBarProfile", sender: place)
            }
        }
        
    }
    
    // Update bars for region shown on map once the user is done scrolling
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if locationManager.location != nil {
            searchForBarsInRegion(mapView.region)
        }
    }

    
    // MARK: - Location delegate methods
    
    //TODO: - Change function 
    // Need to change method to significant location updates. Used the current method for testing purposes
    // After a significant user location update find bars around user and calls method to monitor those regions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        circleQuery?.removeAllObservers()
        stopMonitoringRegions()
        circleQuery = geoFire.queryAtLocation(locations[0], withRadius: 4)
        let handle = circleQuery?.observeEventType(.KeyEntered) { (placeID, location) in
            rootRef.child("bars").child(placeID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.createAndMonitorBar(snap, location: location)
                }
            })
        }
        handles.append(handle!)
    }
    
    
    // Increment users there if user enters bar region
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let placeID = region.identifier
        let barRef = rootRef.child("bars").child(placeID)
        barRef.child("usersThere").runTransactionBlock { (currentData) -> FIRTransactionResult in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! + 1
            return FIRTransactionResult.successWithValue(currentData)
        }
    }
    
    // Decrement users there if user leaves bar region
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        let placeID = region.identifier
        let barRef = rootRef.child("bars").child(placeID)
        barRef.child("usersThere").runTransactionBlock { (currentData) -> FIRTransactionResult in
            var value = currentData.value as? Int
            if (value == nil) {
                value = 0
            }
            currentData.value = value! - 1
            return FIRTransactionResult.successWithValue(currentData)
        }
    }
    
    // MARK: - Helper methods
    // Start updating location if allowed, if not prompts user to settings
    func checkAuthStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            mapView.showsUserLocation = true
            locationManager.startMonitoringSignificantLocationChanges()
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
        case .AuthorizedWhenInUse, .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to be notified about adorable kittens near you, please open this app's settings and set location access to 'Always'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // Remove old observers and anotaions add new one for current region passed in, but it doesnt do anything to the
    // regions that are being monitored
    func searchForBarsInRegion(region: MKCoordinateRegion) {
        regionQuery?.removeAllObservers()
        mapView.removeAnnotations(self.mapView.annotations)
        regionQuery = geoFire.queryWithRegion(region)
        let handle = regionQuery?.observeEventType(.KeyEntered) { (placeID, location) in
            rootRef.child("bars").child(placeID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                
                if snap.value!["usersGoing"] as? Int > 0 {
                    let pointAnnoation = BarAnnotation()
                
                    switch snap.value!["usersThere"] as! Int {
                    case 0...25:
                        pointAnnoation.imageName = "red_map_pin.png"
                    case 26...50:
                        pointAnnoation.imageName = "yellow_map_pin.png"
                    case 51...100:
                        pointAnnoation.imageName = "green_map_pin.png"
                    default:
                        pointAnnoation.imageName = "red_map_pin.png"
                    }
                
                    pointAnnoation.coordinate = location.coordinate
                    pointAnnoation.title = snap.value!["barName"] as? String
                    pointAnnoation.subtitle = placeID
                    let annotationView = MKPinAnnotationView(annotation: pointAnnoation, reuseIdentifier: "pin")
                    self.mapView.addAnnotation(annotationView.annotation!)
                }
            })
        }
        handles.append(handle!)
    }
    
    // Zooms to user location and refresh bars in map view
    func zoomToUserLocation(location:CLLocation) {
        let coordinate = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
        mapView.setRegion(coordinate, animated: true)
        searchForBarsInRegion(coordinate)
    }
    
    // Create and monitor regions based on bars near user
    func createAndMonitorBar(barSnap: FIRDataSnapshot, location: CLLocation) {
        let region = CLCircularRegion(center: location.coordinate, radius: barSnap.value!["radius"] as! Double , identifier: barSnap.key)
        locationManager.startMonitoringForRegion(region)
    }
    
    // Stops monitoring the regions
    func stopMonitoringRegions()  {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoringForRegion(region)
        }
    }
    
}
