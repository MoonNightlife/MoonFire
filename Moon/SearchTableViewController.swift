//
//  SearchTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/20/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import RxSwift
import RxCocoa
import SwiftOverlays

class SearchTableViewController: UITableViewController {
    
    // MARK: - Services
    private let searchService: SearchService = FirebaseSearchService()
    private let userService: UserService = FirebaseUserService()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    var remoteConfig: FIRRemoteConfig!
    let searchController = CustomSearchController(searchResultsController: nil)
    var friendRequest = [UserSnapshot]()
    var filteredUserIDs = [String]()
    var profileImages = [UIImage]()
    let currentUserID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
    var requestCount:UInt = 0
    
    // MARK: - Actions
    @IBAction func dismiss(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion:nil)
    }
    
    @IBAction func shareButtonClicked(sender: UIBarButtonItem) {
        
        remoteConfig.fetchWithCompletionHandler { (status, error) in
            if (status == FIRRemoteConfigFetchStatus.Success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
            self.presentShareView()
        }
        
        
    }
    
    func presentShareView() {
        // Set the default sharing message.
        let message = "Moon is a new app that helps you make decisions on where to go out."
        
        if let linkAsString = remoteConfig["linkToAppstore"].stringValue {
            // Set the link to share.
            if let link = NSURL(string: linkAsString)
            {
                let objectsToShare = [message,link]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                self.presentViewController(activityVC, animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func acceptFriendRequest(sender: UIButton) {
        if let userID = self.friendRequest[sender.tag].userID {
    
            userService.acceptFriendRequestForUserWith(UserID: userID)
                .subscribeNext({ (response) in
                    switch response {
                    case .Success:
                        print("request accepted")
                        //TODO: Find a better way to update the table view. this is a code smell. probably should break out the cell into a class of its own and let the cell viewmodel do they heavy lifting of getting the snapshot for user
                        self.getFriendRequestForUserId(self.currentUserID)
                    case .Failure(let error):
                        print(error)
                    }
                })
                .addDisposableTo(disposeBag)
            
        } else {
            print("no user id")
        }
    }
    
    @IBAction func declineFriendRequest(sender: UIButton) {
        // Remove friend request from database
        if let userID = self.friendRequest[sender.tag].userID {
            
            userService.declineFriendRequestFromUser(userID)
                .subscribeNext({ (response) in
                    switch response {
                    case .Success:
                        print("request declined")
                        //TODO: Find a better way to update the table view. this is a code smell
                        self.getFriendRequestForUserId(self.currentUserID)
                    case .Failure(let error):
                        print(error)
                    }
                })
                .addDisposableTo(disposeBag)
            
        } else {
            print("no user id")
        }
    }
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteConfig = FIRRemoteConfig.remoteConfig()
        // When in developer mode the cache is cleared more often
        //let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        //remoteConfig.configSettings = remoteConfigSettings!
        remoteConfig.setDefaultsFromPlistFileName("RemoteConfigDefaults")
        

        
        setUpSearchController()
        setUpView()
        
        
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load tableview with friend request from users
        getFriendRequestForUserId(currentUserID)
        setUpNavigation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        // Pass the user id of the user to the profile view once the user clicks on a cell
        if segue.identifier == "userProfile" {
            if searchController.active {
                (segue.destinationViewController as! UserProfileViewController).userID = filteredUserIDs[(sender as! NSIndexPath).row]
            } else {
                print(friendRequest[(sender as! NSIndexPath).row].userID)
                (segue.destinationViewController as! UserProfileViewController).userID = friendRequest[(sender as! NSIndexPath).row].userID
            }
        }
    }
    
    // MARK: - Helper functions for view
    func getFriendRequestForUserId(userId: String) {
        
        self.friendRequest.removeAll()
        
        userService.getFriendRequestIDs()
            .flatMapLatest({ (result) -> Observable<BackendResult<UserSnapshot>> in
                switch result {
                case .Success(let id):
                    return self.userService.getUserSnapshotForUserType(UserType: UserType.OtherUser(uid: id))
                case .Failure(let error):
                    return Observable.just(BackendResult.Failure(error: error))
                }
            })
            .doOnCompleted({ 
                self.tableView.reloadData()
            })
            .subscribeNext { (result) in
                switch result {
                case .Success(let usersnap):
                    self.friendRequest.append(usersnap)
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
    func setUpSearchController() {
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Users"
        searchController.searchBar.backgroundImage = UIImage(named: "Search_Bar.png")
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
    }
    
    func setUpView() {
        
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
        self.navigationItem.title = "Find Friends"
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
    
}

// MARK - Table View Methods
extension SearchTableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredUserIDs.count
        }
        return friendRequest.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //theme colors
        let customGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
        
        if searchController.active && searchController.searchBar.text != "" {
            
            let userCell = tableView.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath) as! UserSearchResultTableViewCell
            
            // When we create the view model for this view controller, the view model should create the view model for the cell class based on the indexpath
            userCell.userIDForUser = filteredUserIDs[indexPath.row]
            // TODO: figure out the init method for a table view cell created by a story board so this method call doesnt have to be called from this class
            userCell.bindViewModel()
            
            return userCell
        } else {
            let request: UserSnapshot
            
            let requestCell = tableView.dequeueReusableCellWithIdentifier("friendRequest", forIndexPath: indexPath) as! FriendRequestTableViewCell
            
            request = friendRequest[indexPath.row]
            let firstName = request.firstName ?? ""
            let lastName = request.lastName ?? ""
            requestCell.username.text = firstName + " " + lastName
            requestCell.username.textColor = customGray
            requestCell.backgroundColor = UIColor.clearColor()
            
            getProfilePictureForUserId(request.userID!, imageView: requestCell.profilePicture)

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

extension SearchTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (searchController.searchBar.text != "") {
            filterContentForSearchText(searchController.searchBar.text!)
        } else {
            filteredUserIDs.removeAll()
            tableView.reloadData()
        }
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        if searchText.characters.count == 0 {
            self.filteredUserIDs.removeAll()
            self.tableView.reloadData()
            self.removeAllOverlays()
            return
        }
        
        // use atomic update to avoid having invalid responses displayed
        var newFilteredUsers = [(name: String, username: String, uid: String)]()
        
        //let SearchSizeLimit: UInt = 25
        
        searchService.searchForUserIDsWith(SearchText: searchText)
            .subscribeNext { (result) in
                switch result {
                case .Success(let userIDs):
                    self.filteredUserIDs = userIDs
                    self.tableView.reloadData()
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
//        // Search from user with the specific username in the search bar
//        rootRef.child("users")
//            .queryOrderedByChild("username")
//            .queryStartingAtValue(searchText)
//            .queryLimitedToFirst(SearchSizeLimit)
//            .observeSingleEventOfType(.Value, withBlock: { (snap) in
//                
//                // Save the username and the uid of the user that matched the search
//                for snap in snap.children {
//                    let key = snap.key as String
//                    // Dont add the current user to the list of people returned by the search
//                    if key != self.currentUserID {
//                        let user = (((snap as! FIRDataSnapshot).value as! NSDictionary)["name"] as! String, ((snap as! FIRDataSnapshot).value  as! NSDictionary)["username"] as! String, key)
//                        // If the user is already contained in the array because of the searched based off the
//                        // name, then don't add it again
//                        if !newFilteredUsers.contains ({ $0.uid == user.2 }) {
//                            // if the search query matches the username
//                            if user.1.hasPrefix(searchText) {
//                                newFilteredUsers.append(user)
//                            }
//                        }
//                    }
//                }
//                
//                // Search for user with the specific name in the search bar
//                rootRef.child("users")
//                    .queryOrderedByChild("name")
//                    .queryStartingAtValue(searchText.capitalizedString)
//                    .queryLimitedToFirst(SearchSizeLimit)
//                    .observeSingleEventOfType(.Value, withBlock: { (snap) in
//                        
//                        // Save the username and the uid of the user that matched the search
//                        for snap in snap.children {
//                            let key = snap.key as String
//                            // Dont add the current user to the list of people returned by the search
//                            if key != self.currentUserID {
//                                let user = (((snap as! FIRDataSnapshot).value as! NSDictionary)["name"] as! String, ((snap as! FIRDataSnapshot).value as! NSDictionary)["username"] as! String, key)
//                                
//                                // If the user is already contained in the array because of the searched based off the
//                                // username, then don't add it again
//                                if !newFilteredUsers.contains ({ $0.uid == user.2 }) {
//                                    // if the search query matches the user's name
//                                    if user.0.hasPrefix(searchText.capitalizedString) {
//                                        newFilteredUsers.append(user)
//                                    }
//                                }
//                            }
//                        }
//                        
//                        if self.searchController.searchBar.text == searchText {
//                            self.filteredUsers = newFilteredUsers
//                            self.tableView.reloadData()
//                        } else {
//                            print("invalidated response - sent: \(searchText) current: \(self.searchController.searchBar.text!)")
//                        }
//                    }) { (error) in
//                        showAppleAlertViewWithText(error.description, presentingVC: self)
//                }
//            }) { (error) in
//                showAppleAlertViewWithText(error.description, presentingVC: self)
//        }
    }
}
