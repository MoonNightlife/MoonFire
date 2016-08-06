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
import GooglePlaces
import SCLAlertView


class AppleMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Properties
    var handles = [UInt]()
    var regionQuery: GFRegionQuery?
    var circleQuery: GFCircleQuery?
    let placeClient = GMSPlacesClient()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true

        // Zooms to user location when the map is viewed
        if let location = LocationService.sharedInstance.lastLocation {
            zoomToUserLocation(location)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthStatus(self)
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
    @IBAction func goToCurrentLocation(sender: AnyObject) {
        // User has a button to go back to his location if he or she gets lost on the map
        if let location = LocationService.sharedInstance.lastLocation {
            zoomToUserLocation(location)
        } else {
            checkAuthStatus(self)
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
            //TODO: Add additional button for user going to bar
            let btn = UIButton(type: .DetailDisclosure)
            v?.rightCalloutAccessoryView = btn
        } else {
            v!.annotation = annotation
        }
        
        let customPointAnnotation = annotation as! BarAnnotation
        
        // Image set up for pin on map
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
        if LocationService.sharedInstance.lastLocation != nil {
            if mapView.region.IsValid {
                searchForBarsInRegion(mapView.region)
            }
        }
    }

    
    // MARK: - Location delegate methods
    
    //TODO: - Change function 
    // Need to change method to significant location updates. Used the current method for testing purposes
    // After a significant user location update find bars around user and calls method to monitor those regions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        circleQuery?.removeAllObservers()
//        stopMonitoringRegions()
//        circleQuery = geoFire.queryAtLocation(locations[0], withRadius: K.MapView.RadiusToMonitor)
//        let handle = circleQuery?.observeEventType(.KeyEntered) { (placeID, location) in
//            rootRef.child("bars").child(placeID).observeSingleEventOfType(.Value, withBlock: { (snap) in
//                if !(snap.value is NSNull) {
//                    self.createAndMonitorBar(snap, location: location)
//                }
//            })
//        }
//        handles.append(handle!)
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
        let coordinate = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
        mapView.setRegion(coordinate, animated: true)
        searchForBarsInRegion(coordinate)
    }
    
    // Create and monitor regions based on bars near user
    func createAndMonitorBar(barSnap: FIRDataSnapshot, location: CLLocation) {
//        if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion.self) {
//            let region = CLCircularRegion(center: location.coordinate, radius: barSnap.value!["radius"] as! Double , identifier: barSnap.key)
//            locationManager.startMonitoringForRegion(region)
//        }
    }
    
    // Stops monitoring the regions
    func stopMonitoringRegions()  {
//        for region in locationManager.monitoredRegions {
//            locationManager.stopMonitoringForRegion(region)
//        }
    }
    
}

extension MKCoordinateRegion {
    var IsValid: Bool {
        get {
            let latitudeCenter = self.center.latitude
            let latitudeNorth = self.center.latitude + self.span.latitudeDelta/2
            let latitudeSouth = self.center.latitude - self.span.latitudeDelta/2
            
            let longitudeCenter = self.center.longitude
            let longitudeWest = self.center.longitude - self.span.longitudeDelta/2
            let longitudeEast = self.center.longitude + self.span.longitudeDelta/2
            
            let topLeft = CLLocationCoordinate2D(latitude: latitudeNorth, longitude: longitudeWest)
            let topCenter = CLLocationCoordinate2D(latitude: latitudeNorth, longitude: longitudeCenter)
            let topRight = CLLocationCoordinate2D(latitude: latitudeNorth, longitude: longitudeEast)
            
            let centerLeft = CLLocationCoordinate2D(latitude: latitudeCenter, longitude: longitudeWest)
            let centerCenter = CLLocationCoordinate2D(latitude: latitudeCenter, longitude: longitudeCenter)
            let centerRight = CLLocationCoordinate2D(latitude: latitudeCenter, longitude: longitudeEast)
            
            let bottomLeft = CLLocationCoordinate2D(latitude: latitudeSouth, longitude: longitudeWest)
            let bottomCenter = CLLocationCoordinate2D(latitude: latitudeSouth, longitude: longitudeCenter)
            let bottomRight = CLLocationCoordinate2D(latitude: latitudeSouth, longitude: longitudeEast)
            
            return  CLLocationCoordinate2DIsValid(topLeft) &&
                CLLocationCoordinate2DIsValid(topCenter) &&
                CLLocationCoordinate2DIsValid(topRight) &&
                CLLocationCoordinate2DIsValid(centerLeft) &&
                CLLocationCoordinate2DIsValid(centerCenter) &&
                CLLocationCoordinate2DIsValid(centerRight) &&
                CLLocationCoordinate2DIsValid(bottomLeft) &&
                CLLocationCoordinate2DIsValid(bottomCenter) &&
                CLLocationCoordinate2DIsValid(bottomRight) ?
                    true :
            false
        }
    }
}
