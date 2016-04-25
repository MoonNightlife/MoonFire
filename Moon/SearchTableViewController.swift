//
//  SearchTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase

class SearchTableViewController: UITableViewController {

    let searchController = UISearchController(searchResultsController: nil)
    var users = [(name:String, uid:String)]()
    var filteredUsers = [(name:String, uid:String)]()
    
    
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
    }
    
    // MARK: - Table View
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        return users.count
    }
    
          
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath)
        let friend: (name:String, uid:String)
        if searchController.active && searchController.searchBar.text != "" {
            friend = filteredUsers[indexPath.row]
        } else {
            friend = users[indexPath.row]
        }
        cell.textLabel!.text = friend.name
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("userProfile", sender: indexPath)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        rootRef.childByAppendingPath("users").queryOrderedByChild("username").queryEqualToValue(searchText).observeSingleEventOfType(.Value, withBlock: { (snap) in
            
            var newUserResults = [(name:String, uid:String)]()
            for snap in snap.children {
                newUserResults.append((snap.value["username"] as! String,snap.key))
            }
            self.filteredUsers = newUserResults
            self.tableView.reloadData()
        }) { (error) in
            print(error.description)
        }

        
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfile" {
            (segue.destinationViewController as! UserProfileViewController).userID = filteredUsers[(sender as! NSIndexPath).row].uid
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
