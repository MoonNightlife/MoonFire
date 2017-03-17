//
//  FriendsTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import RxSwift
import SwiftOverlays

class FriendsTableViewController: UITableViewController, UISearchBarDelegate  {
    
    // MARK: - Services
    let userService: UserService = FirebaseUserService()
    
    // MARK: - Properties
    var currentUser: FIRDatabaseReference! = nil
    let searchController = UISearchController(searchResultsController: nil)
    var friends = [String]()
    var filteredFriends = [String]()
    let disposeBag = DisposeBag()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSearchController()
        setUpBackground()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpNavigation()
        getFriends()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        //TODO: when i fix the way the search is done, remove this code
        searchController.searchBar.hidden = true
        // and uncomment this code
        //tableView.tableHeaderView = searchController.searchBar

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
        
        userService.getFriendIDs()
            .subscribeNext { (result) in
                switch result {
                case .Success(let friendIDs):
                    self.friends = friendIDs
                    self.tableView.reloadData()
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
    // MARK: - Table view delegate/datasource functions
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredFriends.count
        }
        return friends.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let userCell = tableView.dequeueReusableCellWithIdentifier("friend", forIndexPath: indexPath) as! UserSearchResultTableViewCell
        
        var friendID: String
        if searchController.active && searchController.searchBar.text != "" {
            friendID = filteredFriends[indexPath.row]
        } else {
            friendID = friends[indexPath.row]
        }
        userCell.userIDForUser = friendID
        userCell.bindViewModel()
        
        return userCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showFriendsProfile", sender: indexPath)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        // Pass the user id of the user to the profile view once the user clicks on a cell
        if segue.identifier == "showFriendsProfile" {
            if searchController.active == false {
                (segue.destinationViewController as! UserProfileViewController).userID = friends[(sender as! NSIndexPath).row]
            } else {
                (segue.destinationViewController as! UserProfileViewController).userID = filteredFriends[(sender as! NSIndexPath).row]
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
        //TODO: Fix the way the users are searched
//        filteredFriends = friends.filter { friend in
//            return friend.name.lowercaseString.containsString(searchText.lowercaseString)
//        }
//        tableView.reloadData()
    }
}
