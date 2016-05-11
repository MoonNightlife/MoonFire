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

class AppleMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    var regionQuery: GFRegionQuery?
    let locationManager = CLLocationManager()
    let placeClient = GMSPlacesClient()
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthStatus()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let location = locationManager.location {
            zoomToUserLocation(location)
        } else {
            print("No Location")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showBarProfile" {
            (segue.destinationViewController as! BarProfileViewController).barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - Actions
    
    @IBAction func refreshBarsShownOnScreen(sender: AnyObject) {
        searchForBarsInRegion(mapView.region)
    }
    
    @IBAction func goToCurrentLocation(sender: AnyObject) {
        if let location = locationManager.location {
        zoomToUserLocation(location)
        } else {
            print("No Location")
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
        v!.image = UIImage(named:customPointAnnotation.imageName)
        
        return v
    }
    
    // Looks up the bar that was selected on the map, and displays the bar profile
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let placeID = view.annotation?.title
        
        placeClient.lookUpPlaceID(placeID!!) { (place, error) in
            if let error = error {
                print(error.description)
            }
            
            if let place = place {
                self.performSegueWithIdentifier("showBarProfile", sender: place)
            }
        }
        
    }
    
    // MARK: - Helper methods
    
    // Start updating location if allowed
    func checkAuthStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
         
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    // Remove old observers and add new one for current region passed in
    func searchForBarsInRegion(region: MKCoordinateRegion) {
        regionQuery?.removeAllObservers()
        regionQuery = geoFire.queryWithRegion(region)
        regionQuery?.observeEventType(.KeyEntered) { (placeID, location) in
            rootRef.childByAppendingPath("bars").childByAppendingPath(placeID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                let pointAnnoation = BarAnnotation()
                
                switch snap.value["usersGoing"] as! Int {
                case 0...5:
                    pointAnnoation.imageName = "Low volume"
                case 6...10:
                    pointAnnoation.imageName = "Low medium volume"
                case 11...15:
                    pointAnnoation.imageName = "High medium volume"
                case 16...20:
                    pointAnnoation.imageName = "High volume"
                default:
                    pointAnnoation.imageName = "Low volume"
                }
                
                
                pointAnnoation.coordinate = location.coordinate
                pointAnnoation.title = placeID
                let annotationView = MKPinAnnotationView(annotation: pointAnnoation, reuseIdentifier: "pin")
                self.mapView.addAnnotation(annotationView.annotation!)
            })
            
        }
    }
    
    // Zooms to user location and refresh bars in map view
    func zoomToUserLocation(location:CLLocation) {
        let coordinate = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
        mapView.showsUserLocation = true
        mapView.setRegion(coordinate, animated: true)
        searchForBarsInRegion(coordinate)
    }
    
}
