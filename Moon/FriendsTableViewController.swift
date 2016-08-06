//
//  FriendsTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SwiftOverlays

class FriendsTableViewController: UITableViewController, UISearchBarDelegate  {
    
    // MARK: - Properties
    var currentUser: FIRDatabaseReference! = nil
    let searchController = UISearchController(searchResultsController: nil)
    var friends = [(name:String, uid:String)]()
    var filteredFriends = [(name:String, uid:String)]()
    var handles = [UInt]()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSearchController()
        setUpBackground()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpNavigation()
        showWaitOverlay()
        getFriends()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    // MARK: - Helper functions for view
    func setUpSearchController() {
        // Set up the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.backgroundImage = UIImage(named: "Search_Bar.png")
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.barStyle = .Default
        searchController.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // Set up the Scope Bar
        tableView.tableHeaderView = searchController.searchBar

    }
    
    func setUpBackground() {
        // Background set up
        let goingToImage = "Moons_View_Background"
        let image = UIImage(named: goingToImage)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height)
        tableView.addSubview(imageView)
        tableView.sendSubviewToBack(imageView)
    }
    
    func setUpNavigation(){
        
        //navigation controller set up
        self.navigationItem.title = "Friends"
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
    
    func getFriends() {
        // Finds the friends for the users
        let handle = currentUser.child("friends").observeEventType(.Value, withBlock: { (snap) in
            self.removeAllOverlays()
            var newFriendList = [(name:String, uid:String)]()
            for friend in snap.children {
                newFriendList.append((friend.key,friend.value))
            }
            self.friends = newFriendList
            self.tableView.reloadData()
        }) { (error) in
            self.removeAllOverlays()
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }
    
    // MARK: - Table view delegate/datasource functions
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
        cell.textLabel!.textColor = UIColor.lightGrayColor()
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showFriendsProfile", sender: indexPath)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the user id of the user to the profile view once the user clicks on a cell
        if segue.identifier == "showFriendsProfile" {
            if searchController.active == false {
                (segue.destinationViewController as! UserProfileViewController).userID = friends[(sender as! NSIndexPath).row].uid
            } else {
                (segue.destinationViewController as! UserProfileViewController).userID = filteredFriends[(sender as! NSIndexPath).row].uid
            }
        }
    }

}

extension FriendsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating delegate/helper functions
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredFriends = friends.filter { friend in
            return friend.name.lowercaseString.containsString(searchText.lowercaseString)
        }
        tableView.reloadData()
    }
}
