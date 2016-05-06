//
//  BarFeedTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 5/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class BarFeedTableViewController: UITableViewController {
    
    struct barActivity {
        let userName: String?
        let userID: String?
        let barName: String?
        let barID: String?
        let time: String?
    }
    
    var friendsList = [String]()
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
        cell.UserName.text = activities[indexPath.row].userName
        cell.BarName.text = activities[indexPath.row].barName
        getElaspedTime(activities[indexPath.row].time!)
        
        cell.Time.text = getElaspedTime(activities[indexPath.row].time!)

        return cell
    }
    
    // Returns the time since the bar activity was first created
    func getElaspedTime(fromDate: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .FullStyle
        dateFormatter.dateStyle = .FullStyle
        let activityDate = dateFormatter.dateFromString(fromDate)
        let elaspedTime = (activityDate?.timeIntervalSinceNow)
        
        // Display correct time. hours or minutes
        if (elaspedTime! * -1) < 60 {
            return "<1m ago"
        } else if (elaspedTime! * -1) < 3600 {
            return "\(Int(elaspedTime! / (-60)))m ago"
        } else {
            return "\(Int(elaspedTime! / (-3600)))h ago"
        }
    }

}
