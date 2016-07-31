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

    @IBOutlet weak var userSearchBar: UISearchBar!
    let searchController = CustomSearchController(searchResultsController: nil)
    var friendRequest = [User]()
    var filteredUsers = [(name:String, username:String, uid:String)]()
    var profileImages = [UIImage]()
    let currentUserID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    var requestCount:UInt = 0
    
    //@IBOutlet weak var friendRequestLabel: UILabel!
    @IBAction func acceptFriendRequest(sender: UIButton) {
        
        exchangeCurrentBarActivitesWithCurrentUser(friendRequest[sender.tag].userID!)
        
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
        searchController.searchBar.placeholder = "Search Users"
        searchController.searchBar.backgroundImage = UIImage(named: "SearchBar2.png")
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.barStyle = .Default
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        self.tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.autocapitalizationType = .None
        searchController.navigationController?.navigationBar.barTintColor = UIColor.clearColor()
        
        // Prevent the navigation bar from being hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        
        
        // Background set up
        let goingToImage = "Moons_View_Background.png"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
        
    
        //tableView set up
        self.tableView.rowHeight = 70
        self.tableView.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = UIColor.whiteColor()
        
    }
    
    
    func setUpNavigation(){
        
        //navigation controller set up
        self.navigationItem.title = "Friend Request"
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
        super.viewWillAppear(animated)
        
        // Load tableview with friend request from users
        showWaitOverlay()
        getFriendRequestForUserId(currentUserID)
        setUpNavigation()
    }
    
    // MARK: - Helper functions for view
    func getFriendRequestForUserId(userId: String) {
        let handle = rootRef.child("friendRequest").child(userId).observeEventType(.Value, withBlock: { (snap) in
            // Save the username and the uid of the user that matched the search
            var tempRequest = [User]()
            for request in snap.children {
                // Will load profile picture when creating table view cell
                tempRequest.append(User(name: request.key, userID: request.value, profilePicture: nil, privacy: nil))
            }
            self.friendRequest = tempRequest
            self.removeAllOverlays()
            self.tableView.reloadData()
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
            self.removeAllOverlays()
        }
        handles.append(handle)
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    // MARK: - Table View
    
    
    // The method called when the user updates the information in the search bar
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        //var usernameDone = false
        let nameDone = true
        showWaitOverlay()
        filteredUsers.removeAll()
        
        print(searchText)
        // Search from user with the specific username in the search bar
        rootRef.child("users").queryOrderedByChild("username").queryStartingAtValue(searchText).queryLimitedToFirst(10).observeSingleEventOfType(.Value, withBlock: { (snap) in
            print(snap.childrenCount)
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
            //usernameDone = true
            if nameDone {
                self.removeAllOverlays()
                self.tableView.reloadData()
            }
            
        }) { (error) in
            showAppleAlertViewWithText(error.description, presentingVC: self)
            self.removeAllOverlays()
        }
        
        //        // Search for user with the specific name in the search bar
        //        rootRef.child("users").queryOrderedByChild("name").queryStartingAtValue(searchText).observeSingleEventOfType(.Value, withBlock: { (snap) in
        //            // Save the username and the uid of the user that matched the search
        //            for snap in snap.children {
        //                let key = snap.key as String
        //                // Dont add the current user to the list of people returned by the search
        //                if key != self.currentUserID {
        //                    let user = (snap.value["name"] as! String,snap.value["username"] as! String,key)
        //                    // If the user is already contained in the array because of the searched based off the
        //                    // username, then don't add it again
        //                    if !self.filteredUsers.contains ({ $0.uid == user.2 }) {
        //                        self.filteredUsers.append(user)
        //                    }
        //                }
        //            }
        //            nameDone = true
        //            if usernameDone {
        //                self.removeAllOverlays()
        //                self.tableView.reloadData()
        //            }
        //
        //            }) { (error) in
        //                showAppleAlertViewWithText(error.description, presentingVC: self)
        //                self.removeAllOverlays()
        //        }
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
           // friendRequestLabel.text = "Search Results"
            return filteredUsers.count
        }
       // friendRequestLabel.text = "Friend Requests"
        return friendRequest.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //theme colors
        let customGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
        
        if searchController.active && searchController.searchBar.text != "" {
            let friend: (name:String, username:String,uid:String)
            let friendCell = tableView.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath)
            friend = filteredUsers[indexPath.row]
            friendCell.textLabel!.text = friend.name
            friendCell.textLabel!.textColor = customGray
            friendCell.detailTextLabel?.text = friend.username
            friendCell.detailTextLabel?.textColor = customBlue
            friendCell.backgroundColor = UIColor.clearColor()
            return friendCell
        } else {
            let request: User
            let requestCell = tableView.dequeueReusableCellWithIdentifier("friendRequest", forIndexPath: indexPath) as! FriendRequestTableViewCell
            request = friendRequest[indexPath.row]
            requestCell.username.text = request.name
            requestCell.username.textColor = customGray
            requestCell.backgroundColor = UIColor.clearColor()
            
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            indicator.center = CGPointMake(requestCell.profilePicture.frame.size.width / 2, requestCell.profilePicture.frame.size.height / 2)
            requestCell.profilePicture.addSubview(indicator)
            indicator.startAnimating()
            
            
              getProfilePictureForUserId(request.userID!, imageView: requestCell.profilePicture, indicator: indicator, vc: self)

            requestCell.profilePicture.layer.masksToBounds = false

            requestCell.profilePicture.layer.cornerRadius = requestCell.profilePicture.frame.size.height / 2
            
            requestCell.profilePicture.clipsToBounds = true
            
            requestCell.acceptButton.tag = indexPath.row
            requestCell.acceptButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            requestCell.declineButton.tag = indexPath.row

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
        if (searchController.searchBar.text != "") {
            filterContentForSearchText(searchController.searchBar.text!)
        } else {
            filteredUsers.removeAll()
            tableView.reloadData()
        }
    }
    
}
