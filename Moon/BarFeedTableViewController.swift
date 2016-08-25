//
//  BarFeedTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 5/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces
import SwiftOverlays
import ObjectMapper

class BarFeedTableViewController: UITableViewController {
    
    // MARK: - Properties
    var handles = [UInt]()
    let placeClient = GMSPlacesClient()
    var dateFormatter = NSDateFormatter()
    var activities = [BarActivity2]() {
        didSet {
            
            if activities.isEmpty {
                setEmptyBackground()
            } else {
                tableView.backgroundView = nil
            }
            // Sorts the array based on the time
            self.activities.sortInPlace {
                return $0.time!.timeIntervalSinceNow > $1.time!.timeIntervalSinceNow
            }

            // Update "last updated" title for refresh control
//            let now = NSDate()
//            let updateString = "Last Updated at " + self.dateFormatter.stringFromDate(now)
//            refreshControl!.attributedTitle = NSAttributedString(string: updateString)
            self.refreshControl?.endRefreshing()
            
            
            if !checkIfSameBarActivities(oldValue, group2: activities) {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func showProfile(sender: UIButton) {
        performSegueWithIdentifier("userProfile", sender: sender)
    }
    
    @IBAction func showBar(sender: UIButton) {
        SwiftOverlays.showBlockingWaitOverlay()
        // Looks up the bar from the google places API
        placeClient.lookUpPlaceID(activities[sender.tag].barId!) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up date formatter to be used for the refresh control title when the user pulls down
        self.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        viewSetUp()
    }
    
    override func viewWillAppear(animated: Bool) {
        setUpNavigation()
        reloadUsersBarFeed()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfile" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = activities[(sender!.tag)].userId
        }
        if segue.identifier == "barProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    //Add functionality Evan (PUSSY) ( . Y . ) lol
    func setEmptyBackground(){
        
        // Background set up if there are no friends
        let goingToImage = "no_friends_background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        tableView.backgroundView = imageView
        
    }
    
    // MARK: - Helper functions for view
    func setUpNavigation() {
        // Navigation controller set up
        self.navigationItem.title = "Moon's View"
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        // Top View set up
        let header = "Header_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
    }
    
    func viewSetUp(){
        // TableView set up
        tableView.rowHeight = 75
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        // Background set up
        let goingToImage = "Moons_View_Background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
        // Add the refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.reloadUsersBarFeed), forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    func reloadUsersBarFeed() {
        // Loads the user's moon's view with updated information
        currentUser.child("barFeed").observeSingleEventOfType(.Value, withBlock: { (barFeedSnap) in
            var tempActivities = [BarActivity2]()
            var activityCount:UInt = 0
            // If feed is empty reload table view with nothing
            if barFeedSnap.childrenCount == 0 {
                self.removeAllOverlays()
                self.activities = tempActivities
            }
            // Grab all the activity objects
            for child in barFeedSnap.children {
                if let activityID: FIRDataSnapshot = child as? FIRDataSnapshot {
                    rootRef.child("barActivities").child(activityID.key).observeSingleEventOfType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull),let barAct = snap.value as? [String : AnyObject] {
                            
                            let userId = Context(id: snap.key)
                            let activity = Mapper<BarActivity2>(context: userId).map(barAct)
                            activityCount += 1
                            if seeIfShouldDisplayBarActivity(activity!) {
                                tempActivities.append(activity!)
                            }
                            
                            // If all activities are obtained then reload table view
                            if activityCount == barFeedSnap.childrenCount {
                                // When the activities are set to the global variable the activities are sorted and reloaded
                                self.activities = tempActivities
                            }
                        }
                        }, withCancelBlock: { (error) in
                            showAppleAlertViewWithText(error.description, presentingVC: self)
                    })
                }
            }
            }, withCancelBlock: { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // TODO: Find a way to delete this horse shit
        let fontName = self.view.frame.size.height / 37.05
        
        let  cell = tableView.dequeueReusableCellWithIdentifier("barActivityCell", forIndexPath: indexPath) as! BarActivityTableViewCell
        
        // Sets a circular profile pic
        cell.profilePicture.image = UIImage(named: "translucent_bar_view.png")
        cell.profilePicture.layer.masksToBounds = false
        cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.size.height/2
        cell.profilePicture.clipsToBounds = true
        getProfilePictureForUserId(activities[indexPath.row].userId!, imageView: cell.profilePicture)
        
        cell.backgroundColor = UIColor.clearColor()
        
        cell.user.setTitle(activities[indexPath.row].userName! , forState: .Normal)
        cell.user.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        cell.user.titleLabel?.font = UIFont(name: "Roboto-Bold", size: fontName)
  
        cell.bar.setTitle(activities[indexPath.row].barName, forState: .Normal)
        cell.bar.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
        // TODO: Find out if we need this
        //cell.bar.titleLabel?.font = UIFont(name: "Roboto-Bold ", size: 5 )
        
        cell.Time.text = getElaspedTimefromDate(activities[indexPath.row].time!)
        cell.Time.textColor = UIColor.grayColor()
        
        // Add the functionality to view bar profiles and user profiles. The button tag will tell the button which activity in the array the user is clicking on
        cell.user.addTarget(self, action: #selector(BarFeedTableViewController.showProfile(_:)), forControlEvents: .TouchUpInside)
        cell.bar.addTarget(self, action: #selector(BarFeedTableViewController.showBar(_:)), forControlEvents: .TouchUpInside)
        cell.user.tag = indexPath.row
        cell.bar.tag = indexPath.row

        return cell
    }
    
}
