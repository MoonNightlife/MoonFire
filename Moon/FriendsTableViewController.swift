//
//  FriendsTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class FriendsTableViewController: UITableViewController  {
    
    let searchController = UISearchController(searchResultsController: nil)
    var friends = [(name:String, uid:String)]()
    var filteredFriends = [(name:String, uid:String)]()
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the Scope Bar
        //searchController.searchBar.scopeButtonTitles = ["All", "Chocolate", "Hard", "Other"]
        tableView.tableHeaderView = searchController.searchBar
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Finds the friends for the users
        currentUser.childByAppendingPath("friends").queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let friends = snap {
                var newFriendList = [(name:String, uid:String)]()
                for friend in friends.children {
                    newFriendList.append((friend.key,friend.value))
                }
                self.friends = newFriendList
                self.tableView.reloadData()
            }
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
            return filteredFriends.count
        }
        return friends.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friend", forIndexPath: indexPath)
        let friend: (name:String, uid:String)
        if searchController.active && searchController.searchBar.text != "" {
            friend = filteredFriends[indexPath.row]
        } else {
            friend = friends[indexPath.row]
        }
        cell.textLabel!.text = friend.name
        return cell
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
    
    filteredFriends = friends.filter { friend in
    return friend.name.lowercaseString.containsString(searchText.lowercaseString)
    }
    
    tableView.reloadData()
    }

}

extension FriendsTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        // Change data
    }
}

extension FriendsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
