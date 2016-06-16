//
//  BarFeedTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 5/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import SwiftOverlays

class BarFeedTableViewController: UITableViewController {
    
    
    
    var friendsList = [String]()
    let placeClient = GMSPlacesClient()
    var activities = [barActivity]() {
        didSet {
            // Sorts the array based on the time
            self.activities.sortInPlace {
                let dateFormatter = NSDateFormatter()
                dateFormatter.timeStyle = .FullStyle
                dateFormatter.dateStyle = .FullStyle
                return dateFormatter.dateFromString($0.time!)?.timeIntervalSinceNow > dateFormatter.dateFromString($1.time!)?.timeIntervalSinceNow
            }
            self.tableView.reloadData()
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
    }
    
    override func viewWillAppear(animated: Bool) {
        monitorUsersBarFeed()
    }
    
    // Monitors the user's bar feed for updated bar activities
    func monitorUsersBarFeed() {
        // Looks at users feed and grabs barActivities
        currentUser.childByAppendingPath("barFeed").observeEventType(.Value, withBlock: { (barFeedSnap) in
            var tempActivities = [barActivity]()
            // If feed is empty reload table view with nothing
            if barFeedSnap.childrenCount == 0 {
                self.activities = tempActivities
            }
            // Grab all the activity objects
            for child in barFeedSnap.children {
                if let activityID: FDataSnapshot = child as? FDataSnapshot {
                    rootRef.childByAppendingPath("barActivities").childByAppendingPath(activityID.key).observeSingleEventOfType(FEventType.Value, withBlock: { (snap) in
                        tempActivities.append(barActivity(userName: (snap.value["userName"] as! String), userID: snap.key, barName: (snap.value["barName"] as! String), barID: (snap.value["barID"] as! String), time: (snap.value["time"] as! String)))
                        // If all activities are obtained then reload table view
                        if UInt(tempActivities.count) == barFeedSnap.childrenCount {
                            self.activities = tempActivities
                        }
                        }, withCancelBlock: { (error) in
                            print(error.description)
                    })
                }
            }
            }, withCancelBlock: { (error) in
                print(error.description)
        })

    }
    
    override func viewDidDisappear(animated: Bool) {
        currentUser.removeAllObservers()
        rootRef.removeAllObservers()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return activities.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("barActivityCell", forIndexPath: indexPath) as! BarActivityTableViewCell
        cell.user.setTitle(activities[indexPath.row].userName, forState: .Normal)
        cell.bar.setTitle(activities[indexPath.row].barName, forState: .Normal)
        getElaspedTime(activities[indexPath.row].time!)
        cell.Time.text = getElaspedTime(activities[indexPath.row].time!)
        
        // Sets indicator view for image view
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicator.startAnimating()
        indicator.center = cell.profilePicture.center
        cell.profilePicture.addSubview(indicator)
        
        // Sets a circular profile pic
        cell.profilePicture.layer.borderWidth = 1.0
        cell.profilePicture.layer.masksToBounds = false
        cell.profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.size.height/2
        cell.profilePicture.clipsToBounds = true
        
        cell.user.addTarget(self, action: #selector(BarFeedTableViewController.showProfile(_:)), forControlEvents: .TouchUpInside)
        cell.bar.addTarget(self, action: #selector(BarFeedTableViewController.showBar(_:)), forControlEvents: .TouchUpInside)
        cell.user.tag = indexPath.row
        cell.bar.tag = indexPath.row
    rootRef.childByAppendingPath("users").childByAppendingPath(activities[indexPath.row].userID!).childByAppendingPath("profilePicture").observeSingleEventOfType(.Value, withBlock: { (snap) in
        print(snap.value)
        if !(snap.value is NSNull) {
                let imageData = NSData(base64EncodedString: snap.value as! String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                cell.profilePicture.image = decodedImage
                indicator.stopAnimating()
        } else {
            cell.profilePicture.image = UIImage(named: "defaultPic")
        }
        }) { (error) in
            print(error.description)
        }

        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func showProfile(sender: UIButton) {
        performSegueWithIdentifier("userProfile", sender: sender)
    }
    @IBAction func showBar(sender: UIButton) {
        SwiftOverlays.showBlockingWaitOverlay()
        placeClient.lookUpPlaceID(activities[sender.tag].barID!) { (place, error) in
            if let error = error {
                print(error.description)
            }
            
            if let place = place {
                SwiftOverlays.removeAllBlockingOverlays()
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfile" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = activities[(sender!.tag)].userID
        }
        if segue.identifier == "barProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    


}
