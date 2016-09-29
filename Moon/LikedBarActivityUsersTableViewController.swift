//
//  LikedBarActivityUsersTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 9/28/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SwiftOverlays

struct likedUser {
    var username: String?
    var name: String?
    var userId: String?
    var photo: UIImage?
}

class LikedBarActivityUsersTableViewController: UITableViewController {
    
    var activityId: String?
    var users = [likedUser]()
    var totalUserCount = 0
    var usernameCounter = 0
    var nameCounter = 0

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background set up
        let goingToImage = "Moons_View_Background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showWaitOverlay()
        getListOfUsersIdsThatLikedActivity()
        setUpNavigation()
        
        
    }
    
    func setUpNavigation() {
        // Navigation controller set up
        self.navigationItem.title = "Likes"
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "likedUserToUserProfile" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = sender as! String
        }
    }
    
    // MARK: - Helper functions for getting list of users and their information
    func getListOfUsersIdsThatLikedActivity() {
        // Remove all users for reload
        users.removeAll()
        totalUserCount = 0
        usernameCounter = 0
        nameCounter = 0
        if let id = activityId {
            rootRef.child("barActivities").child(id).child("likedUsers").observeSingleEventOfType(.Value, withBlock: { (snap) in
                if snap.childrenCount == 0 {
                    self.removeAllOverlays()
                }
                self.totalUserCount = Int(snap.childrenCount)
                for user in snap.children {
                    let userId = (user as! FIRDataSnapshot).key
                    self.users.append(likedUser(username: nil, name: nil, userId: userId, photo: nil))
                    self.getUsernamesForUserId(userId)
                    self.getNameForUserId(userId)
                }
                
                }, withCancelBlock: { (error) in
                    print(error)
            })
        }
    }
    
    func getUsernamesForUserId(userId: String) {
        rootRef.child("users").child(userId).child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let index = self.users.indexOf({$0.userId == userId}) {
                if let username = snap.value as? String {
                    self.users[index].username = username
                }
            }
            
            // Increment the number of usernames found
            self.usernameCounter += 1
            
            // Check if all the names and usernames have been found
            if self.nameCounter == self.totalUserCount && self.usernameCounter == self.totalUserCount {
                self.removeAllOverlays()
                self.tableView.reloadData()
            }
            
        }) { (error) in
            print(error)
        }
    }
    
    func getNameForUserId(userId: String) {
        rootRef.child("users").child(userId).child("name").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let index = self.users.indexOf({$0.userId == userId}) {
                if let name = snap.value as? String {
                    self.users[index].name = name
                }
            }
            
            // Increment the number of names found
            self.nameCounter += 1
            
            // Check if all the names and usernames have been found
            if self.nameCounter == self.totalUserCount && self.usernameCounter == self.totalUserCount {
                self.removeAllOverlays()
                self.tableView.reloadData()
            }
 
        }) { (error) in
            print(error)
        }
    }


    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("likedUserCell") as! LikedUserTableViewCell
        
        let user = users[indexPath.row]
        
        let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
        
        getProfilePictureForUserId(user.userId!, imageView: cell.userProfile)
        cell.username.text = user.username
        cell.username.font = UIFont(name: "Roboto-Bold", size: 16)
        cell.username.textColor = UIColor.lightGrayColor()
        
        cell.name.text = user.name
        cell.name.textColor = customBlue
        cell.name.font = UIFont(name: "Roboto-Bold", size: 11)
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("likedUserToUserProfile", sender: users[indexPath.row].userId!)
    }

}
