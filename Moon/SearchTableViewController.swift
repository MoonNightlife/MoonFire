//
//  SearchTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SwiftOverlays

class SearchTableViewController: UITableViewController {
    
    var handles = [UInt]()

    let searchController = UISearchController(searchResultsController: nil)
    var friendRequest = [User]()
    var filteredUsers = [(name:String, username:String, uid:String)]()
    var profileImages = [UIImage]()
    let currentUserID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    var requestCount:UInt = 0
    
    @IBOutlet weak var friendRequestLabel: UILabel!
    @IBAction func acceptFriendRequest(sender: UIButton) {
        
        // Adds person requesting to current user's friend list
        currentUser.child("friends").child(friendRequest[sender.tag].name!).setValue(friendRequest[sender.tag].userID!)
        
        // Get current user's username
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            // Add self to friends list of person requesting
            rootRef.child("users/\(self.friendRequest[sender.tag].userID!)/friends").child(snap.value as!String).setValue(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)
            // Remove friend request from database
            rootRef.child("friendRequest/\(self.currentUserID)/\(self.friendRequest[sender.tag].name!)").removeValue()
        }, withCancelBlock: { (error) in
            print(error.description)
        })
        
    }
    
    @IBAction func declineFriendRequest(sender: UIButton) {
        // Remove friend request from database
        rootRef.child("friendRequest/\(self.currentUserID)/\(self.friendRequest[sender.tag].name!)").removeValue()
    }

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the Search Bar 
        self.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.autocapitalizationType = .None
        searchController.navigationController?.navigationBar.barTintColor = UIColor.darkGrayColor()
        
        // Prevent the navigation bar from being hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        
        // Background set up
        let goingToImage = "bar_background_750x1350.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
        //tableView set up 
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None

        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load tableview with friend request from users
        SwiftOverlays.showBlockingWaitOverlay()
        let handle = rootRef.child("friendRequest").child(currentUserID).observeEventType(.Value, withBlock: { (snap) in
            // Save the username and the uid of the user that matched the search
            var tempRequest = [User]()
            self.requestCount = snap.childrenCount
            var imageCount: UInt = 0
            for request in snap.children {
                imageCount += 1
                self.loadProfilePictureForFriendRequest(request.value,imageCount: imageCount)
                tempRequest.append(User(name: request.key, userID: request.value, profilePicture: nil, privacy: nil))
            }
            self.friendRequest = tempRequest
            // Remove overlay if there are no friend request
            if snap.childrenCount == 0 {
                SwiftOverlays.removeAllBlockingOverlays()
                self.tableView.reloadData()
            }
            }) { (error) in
                print(error.description)
                SwiftOverlays.removeAllBlockingOverlays()
            }
        handles.append(handle)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    // Helper Functions
    
    func loadProfilePictureForFriendRequest(userID:String, imageCount: UInt) {
        rootRef.child("users").child(userID).child("profilePicture").observeSingleEventOfType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull) {
                    self.profileImages.append(stringToUIImage(snap.value as! String, defaultString: "defaultPic")!)
                }else {
                    self.profileImages.append(UIImage(contentsOfFile: "defaultPic")!)
                }
                if self.requestCount == imageCount {
                    SwiftOverlays.removeAllBlockingOverlays()
                    self.tableView.reloadData()
                }
            }) { (error) in
                print(error)
        }
    }
    
    // MARK: - Table View
    
    
    // The method called when the user updates the information in the search bar
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        showWaitOverlay()
        filteredUsers.removeAll()
        
        // Search from user with the specific username in the search bar
        rootRef.child("users").queryOrderedByChild("username").queryEqualToValue(searchText).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            // Save the username and the uid of the user that matched the search
            for snap in snap.children {
                let key = snap.key as String
                // Dont add the current user to the list of people returned by the search
                if key != self.currentUserID {
                    let user = (snap.value["name"] as! String,snap.value["username"] as! String,key)
                    // If the user is already contained in the array because of the searched based off the
                    // name, then don't add it again
                    if !self.filteredUsers.contains ({ $0.uid == user.2 }) {
                        self.filteredUsers.append(user)
                    }
                }
            }
            self.tableView.reloadData()
            
        }) { (error) in
            print(error.description)
        }
        
        // Search for user with the specific name in the search bar
        rootRef.child("users").queryOrderedByChild("name").queryEqualToValue(searchText).observeSingleEventOfType(.Value, withBlock: { (snap) in
            // Save the username and the uid of the user that matched the search
            for snap in snap.children {
                let key = snap.key as String
                // Dont add the current user to the list of people returned by the search
                if key != self.currentUserID {
                    let user = (snap.value["name"] as! String,snap.value["username"] as! String,key)
                    // If the user is already contained in the array because of the searched based off the
                    // username, then don't add it again
                    if !self.filteredUsers.contains ({ $0.uid == user.2 }) {
                        self.filteredUsers.append(user)
                    }
                }
            }
            self.removeAllOverlays()
            self.tableView.reloadData()
            }) { (error) in
                print(error)
                self.removeAllOverlays()
        }
        tableView.reloadData()
    }
    
    
    // Pass the user id of the user to the profile view once the user clicks on a cell
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfile" {
            if searchController.active {
                (segue.destinationViewController as! UserProfileViewController).userID = filteredUsers[(sender as! NSIndexPath).row].uid
            } else {
                (segue.destinationViewController as! UserProfileViewController).userID = friendRequest[(sender as! NSIndexPath).row].userID
            }
        }
    }
    
}

// MARK - Table View Methods
extension SearchTableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            friendRequestLabel.text = "Search Results"
            return filteredUsers.count
        }
        friendRequestLabel.text = "Friend Requests"
        return friendRequest.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if searchController.active && searchController.searchBar.text != "" {
            let friend: (name:String, username:String,uid:String)
            let friendCell = tableView.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath)
            friend = filteredUsers[indexPath.row]
            friendCell.textLabel!.text = friend.name
            friendCell.textLabel!.textColor = UIColor.whiteColor()
            friendCell.detailTextLabel?.text = friend.username
            friendCell.detailTextLabel?.textColor = UIColor.whiteColor()
            friendCell.backgroundColor = UIColor.clearColor()
            return friendCell
        } else {
            let request: User
            let requestCell = tableView.dequeueReusableCellWithIdentifier("friendRequest", forIndexPath: indexPath) as! FriendRequestTableViewCell
            request = friendRequest[indexPath.row]
            requestCell.username.text = request.name
            requestCell.username.textColor = UIColor.whiteColor()
            requestCell.backgroundColor = UIColor.clearColor()
            
            
            requestCell.profilePicture.image = profileImages[indexPath.row]
            requestCell.profilePicture.layer.borderWidth = 1.0
            requestCell.profilePicture.layer.masksToBounds = false
            requestCell.profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
            requestCell.profilePicture.layer.cornerRadius = requestCell.profilePicture.frame.size.height / 2
            requestCell.profilePicture.clipsToBounds = true
            
            requestCell.acceptButton.tag = indexPath.row
            requestCell.acceptButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            requestCell.acceptButton.layer.borderColor = UIColor.whiteColor().CGColor
            requestCell.acceptButton.layer.borderWidth = 1
            requestCell.acceptButton.layer.cornerRadius = 5
            requestCell.declineButton.tag = indexPath.row
            requestCell.declineButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            requestCell.declineButton.layer.borderColor = UIColor.whiteColor().CGColor
            requestCell.declineButton.layer.borderWidth = 1
            requestCell.declineButton.layer.cornerRadius = 5
            return requestCell
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("userProfile", sender: indexPath)
    }

}

extension SearchTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        // Change data
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
