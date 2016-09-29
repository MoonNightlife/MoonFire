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
    var activitiesUserLikedIds = [String]()
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
            
            self.refreshControl?.endRefreshing()

            if !checkIfSameBarActivities(oldValue, group2: activities) {
                for activity in self.activities {
                    observeLikeCountForActivityFeedCell(activity.userId!)
                }
                self.tableView.reloadData()
                getActivitiesUserLikes()
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
            vc.userID = activities[(sender as! Int)].userId
        }
        if segue.identifier == "barProfile" {
            let vc = segue.destinationViewController as! BarProfileViewController
            vc.barPlace = sender as! GMSPlace
        }
        if segue.identifier == "showLikedTableView" {
            let vc = segue.destinationViewController as! LikedBarActivityUsersTableViewController
            if let id = sender as? String {
                vc.activityId = id
            }
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
        
        // Set local variables for cell
        cell.delegate = self
        // UserId and ActivityId are the same
        cell.activityId = activities[indexPath.row].userId
        cell.index = indexPath.row
        
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
        
        // Add action to heart for liking of status
        let image = UIImage(named: "Heart_Icon2")?.imageWithRenderingMode(.AlwaysTemplate)
        cell.likeButton.imageView?.tintColor = UIColor.grayColor()
        cell.likeButton.setImage(image!, forState: UIControlState.Normal)
        
        // Add the correct amount of likes to cell
        if let likes = activities[indexPath.row].likes {
            cell.numLikeButton.setTitle(String(likes), forState: .Normal)
        } else {
            cell.numLikeButton.setTitle("0", forState: .Normal)

        }

        return cell
    }
    
    // MARK: - Helper functions for managing liking of moon's view activities
    func getActivitiesUserLikes() {
        let handle = rootRef.child("activitiesLiked").child(currentUser.key).observeEventType(.ChildAdded, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.activitiesUserLikedIds.append(snap.key)
                self.changeHeartForActivityWithActivityId(snap.key, color: .Red)
            }
        }) { (error) in
            print(error.description)
        }
        handles.append(handle)
        
        let handle2 = rootRef.child("activitiesLiked").child(currentUser.key).observeEventType(.ChildRemoved, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                self.activitiesUserLikedIds.removeAtIndex(self.activitiesUserLikedIds.indexOf(snap.key)!)
                self.changeHeartForActivityWithActivityId(snap.key, color: .Gray)
            }
        }) { (error) in
            print(error.description)
        }
        handles.append(handle2)
    }
    
    func changeHeartForActivityWithActivityId(activityId: String, color: HeartColor) {
        if let index = self.activities.indexOf({$0.userId == activityId}) {
            
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
        
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? BarActivityTableViewCell

            if let heartButton = cell?.likeButton {
                if color == .Red {
                    heartButton.imageView?.tintColor = UIColor.redColor()
                } else {
                    heartButton.imageView?.tintColor = UIColor.grayColor()
                }
            }
        }
    }
    
    func observeLikeCountForActivityFeedCell(activityId: String) {
        let handle = rootRef.child("barActivities").child(activityId).child("likes").observeEventType(.Value, withBlock: { (snap) in
                if let index = self.activities.indexOf({$0.userId == activityId}) {
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? BarActivityTableViewCell
                    if let likeLabel = cell?.numLikeButton {
                        if !(snap.value is NSNull), let likes = snap.value as? Int{
                            likeLabel.setTitle(String(likes), forState: .Normal)
                        }
                    }
                }
            }) { (error) in
                print(error)
        }
        handles.append(handle)
    }

    
    func seeIfUserLikesBarActivity(activityId: String, index: Int) {
        // The activityId is the same as the userId that is belongs to
        let userId = activityId
        
        // The index is used to find the activity the user is liking and then it is used to retrieve the time stamp
        let activityIndex = index
        let timeStamp = activities[activityIndex].time!.timeIntervalSince1970
        let pathToActivity = rootRef.child("barActivities").child(userId)
        
        // Check firebase to see if the user likes the special
        rootRef.child("activitiesLiked").child(currentUser.key).child(userId).observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull), let timeStampSnap = snap.value as? Double {
                if timeStamp == timeStampSnap {
                    self.likeBarActivity(userId, userCurrentLikesActivity: true, pathToActivity: pathToActivity, timeStamp: timeStamp)
                } else {
                    self.likeBarActivity(userId, userCurrentLikesActivity: false, pathToActivity: pathToActivity, timeStamp: timeStamp)
                }
            } else {
                self.likeBarActivity(userId, userCurrentLikesActivity: false, pathToActivity: pathToActivity, timeStamp: timeStamp)
            }
            }) { (error) in
                print(error)
        }
    }
    
    func likeBarActivity(activityId: String, userCurrentLikesActivity: Bool, pathToActivity: FIRDatabaseReference, timeStamp: NSTimeInterval) {
        if userCurrentLikesActivity {
            
            // Remove the activity from the list of activities the users has liked
            rootRef.child("activitiesLiked").child(currentUser.key).child(activityId).removeValue()
            
            // Remove the current users id from the list of users that has liked the special
            rootRef.child("barActivities").child(activityId).child("likedUsers").child(currentUser.key).removeValue()
            
            decrementLikesOnSpecialWithRef(pathToActivity)
        } else {
            
            // Add activity to the list of the ones the current user has liked
            rootRef.child("activitiesLiked").child(currentUser.key).child(activityId).setValue(timeStamp)
            
            // Add the current users id to the list of users that has liked the current activity
            rootRef.child("barActivities").child(activityId).child("likedUsers").child(currentUser.key).setValue(timeStamp)
            
            incrementLikesOnSpecialWithRef(pathToActivity)
            
            seeIfUserAllowsBarActivityLikeNotifications(activityId, handler: { (allowed) in
                if allowed {
                    // Get the current users username
                    currentUser.child("name").observeSingleEventOfType(.Value, withBlock: { (snap) in
                        print(snap.value as! String + " likes your plan for tonight")
                        sendPush(false, badgeNum: 1, groupId: "Status Likes", title: "Moon", body: snap.value as! String + " likes your plan for tonight.", customIds: [activityId], deviceToken: "nil")
                        }, withCancelBlock: { (error) in
                            print(error)
                    })
                }
            })
        }
    }
}

//MARK: - Bar activity cell protocol
protocol BarActivityCellDelegate {
    func likeButtonTapped(activityId: String, index: Int)
    func numButtonTapped(activityId: String)
    func nameButtonTapped(index: Int)
    func barButtonTapped(index: Int)
}

// MARK: - Cell delegate extension
extension BarFeedTableViewController: BarActivityCellDelegate {
    
    func likeButtonTapped(activityId: String, index: Int) {
        seeIfUserLikesBarActivity(activityId, index: index)
    }
    
    func numButtonTapped(activityId: String) {
        performSegueWithIdentifier("showLikedTableView", sender: activityId)
    }
    
    func nameButtonTapped(index: Int) {
        performSegueWithIdentifier("userProfile", sender: index)
    }
    
    func barButtonTapped(index: Int) {
        SwiftOverlays.showBlockingWaitOverlay()
        // Looks up the bar from the google places API
        placeClient.lookUpPlaceID(activities[index].barId!) { (place, error) in
            SwiftOverlays.removeAllBlockingOverlays()
            if let error = error {
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                self.performSegueWithIdentifier("barProfile", sender: place)
            }
        }
    }
}
