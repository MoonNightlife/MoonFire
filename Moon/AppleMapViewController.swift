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

class AppleMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {


    @IBOutlet weak var mapView: MKMapView!
    
    var regionQuery: GFRegionQuery?
    
    let locationManager = CLLocationManager()
    
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
    @IBAction func refreshBarsShownOnScreen(sender: AnyObject) {
        searchForBarsInCurrentRegion()
    }
    
    @IBAction func goToCurrentLocation(sender: AnyObject) {
        if let location = locationManager.location {
        zoomToUserLocation(location)
        } else {
            print("No Location")
        }
    }
    
    // Remove old observers and add new one for current region shown
    func searchForBarsInCurrentRegion() {
        regionQuery?.removeAllObservers()
        regionQuery = geoFire.queryWithRegion(mapView.region)
        regionQuery?.observeEventType(.KeyEntered) { (placeID, location) in
            rootRef.childByAppendingPath("bars").childByAppendingPath(placeID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                let pointAnnoation = BarAnnotation()
                
                switch snap.value["usersThere"] as! Int {
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        let reuseIdentifier = "pin"
        var v = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if v == nil {
            v = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            v!.canShowCallout = true
        }
        else {
            v!.annotation = annotation
        }
        
        let customPointAnnotation = annotation as! BarAnnotation
        v!.image = UIImage(named:customPointAnnotation.imageName)
        
        return v
    }

    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
       // TODO: direct to settings to change premission
    }
    
    func checkAuthStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
         
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func zoomToUserLocation(location:CLLocation) {
        let coordinate = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
        mapView.showsUserLocation = true
        mapView.setRegion(coordinate, animated: true)
    }
    

}
