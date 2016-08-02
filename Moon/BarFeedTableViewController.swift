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

class BarFeedTableViewController: UITableViewController {
    
    // MARK: - Properties
    var handles = [UInt]()
    var friendsList = [String]()
    let placeClient = GMSPlacesClient()
    var dateFormatter = NSDateFormatter()
    var activities = [barActivity]() {
        didSet {
            // Sorts the array based on the time
            self.activities.sortInPlace {
                let dateFormatter = NSDateFormatter()
                dateFormatter.timeStyle = .FullStyle
                dateFormatter.dateStyle = .FullStyle
                return dateFormatter.dateFromString($0.time!)?.timeIntervalSinceNow > dateFormatter.dateFromString($1.time!)?.timeIntervalSinceNow
            }
            // Update "last updated" title for refresh control
            let now = NSDate()
            let updateString = "Last Updated at " + self.dateFormatter.stringFromDate(now)
            refreshControl!.attributedTitle = NSAttributedString(string: updateString)
            if refreshControl!.refreshing {
                self.refreshControl?.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        viewSetUp()

    }
    
    
    func viewSetUp(){
        
        //tableView set up
        tableView.rowHeight = 75 //UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        //background set up
        let goingToImage = "Moons_View_Background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.reloadUsersBarFeed), forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        
        
        
    }
    
    func setUpNavigation(){
        
        //navigation controller set up
        self.navigationItem.title = "Moon's View"
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
    
    override func viewWillAppear(animated: Bool) {
        showWaitOverlay()
        reloadUsersBarFeed()
        setUpNavigation()
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
            vc.userID = activities[(sender!.tag)].userID
        }
        if segue.identifier == "barProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
    }
    
    // MARK: - Helper functions for view
    func reloadUsersBarFeed() {
        // Looks at users feed and grabs barActivities
        currentUser.child("barFeed").observeSingleEventOfType(.Value, withBlock: { (barFeedSnap) in
            var tempActivities = [barActivity]()
            // If feed is empty reload table view with nothing
            if barFeedSnap.childrenCount == 0 {
                self.removeAllOverlays()
                self.activities = tempActivities
            }
            // Grab all the activity objects
            for child in barFeedSnap.children {
                if let activityID: FIRDataSnapshot = child as? FIRDataSnapshot {
                    rootRef.child("barActivities").child(activityID.key).observeSingleEventOfType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull),let barAct = snap.value {
                            tempActivities.append(barActivity(userName: (barAct["userName"] as! String), userID: snap.key, barName: (barAct["barName"] as! String), barID: (barAct["barID"] as! String), time: (barAct["time"] as! String)))
                            // If all activities are obtained then reload table view
                            if UInt(tempActivities.count) == barFeedSnap.childrenCount {
                                // When the activities are set to the global variable the activities are sorted and reloaded
                                self.removeAllOverlays()
                                self.activities = tempActivities
                            }
                        }
                        }, withCancelBlock: { (error) in
                            self.removeAllOverlays()
                            showAppleAlertViewWithText(error.description, presentingVC: self)
                    })
                }
            }
            }, withCancelBlock: { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return activities.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //magic numbers (Evan is Ugly)
        let fontName = self.view.frame.size.height / 37.05
        //let fontIsGoing = self.view.frame.size.height / 44.46
        //let barFont = self.view.frame.size.height / 55.83
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("barActivityCell", forIndexPath: indexPath) as! BarActivityTableViewCell
        
        cell.user.setTitle(activities[indexPath.row].userName! , forState: .Normal)
        cell.user.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        cell.user.titleLabel?.font = UIFont(name: "Roboto-Bold", size: fontName)
  

        cell.bar.setTitle(activities[indexPath.row].barName, forState: .Normal)
        getElaspedTime(activities[indexPath.row].time!)
        cell.bar.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
        //cell.bar.titleLabel?.font = UIFont(name: "Roboto-Bold ", size: 5 )
        

        cell.backgroundColor = UIColor.clearColor()
        cell.Time.text = getElaspedTime(activities[indexPath.row].time!)
        cell.Time.textColor = UIColor.grayColor()
        
        // Sets indicator view for image view
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        if cell.profilePicture.image == nil {
            indicator.startAnimating()
        }
        indicator.center = CGPointMake(cell.profilePicture.frame.size.width / 2, cell.profilePicture.frame.size.height / 2)
        cell.profilePicture.addSubview(indicator)
        
        // Sets a circular profile pic
        cell.profilePicture.layer.masksToBounds = false
        cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.size.height/2
        cell.profilePicture.clipsToBounds = true
        
        cell.user.addTarget(self, action: #selector(BarFeedTableViewController.showProfile(_:)), forControlEvents: .TouchUpInside)
        cell.bar.addTarget(self, action: #selector(BarFeedTableViewController.showBar(_:)), forControlEvents: .TouchUpInside)
        cell.user.tag = indexPath.row
        cell.bar.tag = indexPath.row
        
        getProfilePictureForUserId(activities[indexPath.row].userID!, imageView: cell.profilePicture, indicator: indicator, vc: self)

        return cell
    }
    
    // MARK: - Actions
    @IBAction func showProfile(sender: UIButton) {
        performSegueWithIdentifier("userProfile", sender: sender)
    }
    
    @IBAction func showBar(sender: UIButton) {
        SwiftOverlays.showBlockingWaitOverlay()
        placeClient.lookUpPlaceID(activities[sender.tag].barID!) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }
    
}
