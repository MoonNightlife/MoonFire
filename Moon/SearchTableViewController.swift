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

    let searchController = UISearchController(searchResultsController: nil)
    var friendRequest = [(name:String, uid:String)]()
    var filteredUsers = [(name:String, username:String, uid:String)]()
    
    @IBAction func acceptFriendRequest(sender: UIButton) {
    
        currentUser.childByAppendingPath("friends").childByAppendingPath(friendRequest[sender.tag].name).setValue(friendRequest[sender.tag].uid)
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            rootRef.childByAppendingPath("users/\(self.friendRequest[sender.tag].uid)/friends").childByAppendingPath(snap.value["username"] as! String).setValue(snap.key)
            rootRef.childByAppendingPath("friendRequest/\(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)/\(self.friendRequest[sender.tag].name)").removeValue()
        }, withCancelBlock: { (error) in
            print(error.description)
        })
        
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
        
        // Prevent the navigation bar from being hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load tableview with friend request from users
        SwiftOverlays.showBlockingWaitOverlay()
         rootRef.childByAppendingPath("friendRequest").childByAppendingPath(NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String).observeEventType(.Value, withBlock: { (snap) in
            // Save the username and the uid of the user that matched the search
            var tempRequest = [(name:String, uid:String)]()
            print(snap)
            for request in snap.children {
                tempRequest.append((request.key, request.value))
            }
            self.friendRequest = tempRequest
            self.tableView.reloadData()
            SwiftOverlays.removeAllBlockingOverlays()
            
            }) { (error) in
                print(error.description)
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        return friendRequest.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if searchController.active && searchController.searchBar.text != "" {
            let friend: (name:String, username:String,uid:String)
            let friendCell = tableView.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath)
            friend = filteredUsers[indexPath.row]
            friendCell.textLabel!.text = friend.name
            friendCell.detailTextLabel?.text = friend.username
            return friendCell
        } else {
            let request: (name:String, uid:String)
            let requestCell = tableView.dequeueReusableCellWithIdentifier("friendRequest", forIndexPath: indexPath) as! FriendRequestTableViewCell
            request = friendRequest[indexPath.row]
            requestCell.username.text = request.name
            requestCell.acceptButton.tag = indexPath.row
            return requestCell
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            performSegueWithIdentifier("userProfile", sender: indexPath)
    }
    
    // The method called when the user updates the information in the search bar
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredUsers.removeAll()
        
        // Search from user with the specific username in the search bar
        rootRef.childByAppendingPath("users").queryOrderedByChild("username").queryEqualToValue(searchText).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            // Save the username and the uid of the user that matched the search
            for snap in snap.children {
                let key = snap.key as String
                let user = (snap.value["name"] as! String,snap.value["username"] as! String,key)
                // If the user is already contained in the array because of the searched based off the
                // name, then don't add it again
                if !self.filteredUsers.contains ({ $0.uid == user.2 }) {
                    self.filteredUsers.append(user)
                }
            }
            self.tableView.reloadData()
            
        }) { (error) in
            print(error.description)
        }
        
        // Search for user with the specific name in the search bar
        rootRef.childByAppendingPath("users").queryOrderedByChild("name").queryEqualToValue(searchText).observeEventType(.Value, withBlock: { (snap) in
            // Save the username and the uid of the user that matched the search
            for snap in snap.children {
                let key = snap.key as String
                let user = (snap.value["name"] as! String,snap.value["username"] as! String,key)
                // If the user is already contained in the array because of the searched based off the
                // username, then don't add it again
                if !self.filteredUsers.contains ({ $0.uid == user.2 }) {
                    self.filteredUsers.append(user)
                }
            }
            self.tableView.reloadData()
            }) { (error) in
                print(error)
        }
        
        tableView.reloadData()
    }
    
    
    // Pass the user id of the user to the profile view once the user clicks on a cell
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfile" {
            if searchController.active {
                (segue.destinationViewController as! UserProfileViewController).userID = filteredUsers[(sender as! NSIndexPath).row].uid
            } else {
                (segue.destinationViewController as! UserProfileViewController).userID = friendRequest[(sender as! NSIndexPath).row].uid
            }
        }
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
