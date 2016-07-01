//
//  FirebaseAPI.swift
//  Moon
//
//  Created by Evan Noble on 6/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

protocol DataProtocol {
    
    // MARK: - User
    func getUserForId(id: String, completionHandler: (user: UserFull?, error: NSError?) -> Void)
    func updateUserInfo(user: UserFull, completionHandler: (error: NSError?) -> Void)
    func updateCityForUserId(id: String, city: CityFull, completionHandler: (error: NSError?) -> Void)
    func updateBarFeedForUserId(id:String, barFeed: BarFeed, completionHandler: (error: NSError?) -> Void)
    func createUser(user: UserFull, completionHandler: (error: NSError?) -> Void)
    func addFriendForUserId(id: String, friend: Friend, completionHandler: (error: NSError?) -> Void)
    func deleteFriendForUserId(id: String, friend: Friend, completionHandler: (error: NSError?) -> Void)
    
    
    // MARK: - Bar
    func getBarForId(id: String, completionHandler: (bar: Bar?, error: NSError?) -> Void)
    func saveBar(bar: Bar, completionHandler: (error: NSError?) -> Void)
    func createBar(bar: Bar, completionHandler: (error: NSError?) -> Void)
    
    // MARK: - Bar Activity
    func getBarActivityForId(id: String, completionHandler: (user: User?, error: NSError?) -> Void)
    func saveBarActivity(barActivity: BarActivity, completionHandler: (error: NSError?) -> Void)
    func createBarActivity(barActivity: BarActivity, completionHandler: (error: NSError?) -> Void)
    
    // MARK: - City
    func getCityForId(id: String, completionHandler: (city: CityFull?, error: NSError?) -> Void)
    
    // MARK: - Specials
    func getSpecialsForBarId(id: String, completionHandler: (specials: [Special]?, error: NSError?) -> Void)
    
    // MARK: - Friend Request
    func getFriendRequestsForUserId(id: String, completionHandler: (friendRequest: [FriendRequest]?, error: NSError?) -> Void)
    func createFriendRequest(friendRequest: FriendRequest, completionHandler: (error: NSError?) -> Void)
    func deleteFriendRequestForId(id: String, completionHandler: (error: NSError?) -> Void)
    
}


class FirebaseDataStore: DataProtocol {
    
    // MARK: - User
    func getUserForId(id: String, completionHandler: (user: UserFull?, error: NSError?) -> Void) {
        rootRef.childByAppendingPath("users").childByAppendingPath(id).observeSingleEventOfType(.Value, withBlock: { (snap) in
            if snap.value is NSNull {
                completionHandler(user: nil, error: nil)
            } else {
                let user = createUserFromSnap(snap)
                completionHandler(user: user, error: nil)
            }
            }) { (error) in
                completionHandler(user: nil, error: error)
        }
    }
    
    func updateUserInfo(user: UserFull, completionHandler: (error: NSError?) -> Void) {
        rootRef.childByAppendingPath("users").childByAppendingPath(user.userId).updateChildValues(userToAnyObject(user)) { (error, firebase) in
            if error != nil {
                completionHandler(error: error)
            } else {
                completionHandler(error: nil)
            }
        }
        
    }
    
    func createUser(user: UserFull, completionHandler: (error: NSError?) -> Void) {
        
    }
    func addFriendForUserId(id: String, friend: Friend, completionHandler: (error: NSError?) -> Void) {
        
    }
    func deleteFriendForUserId(id: String, friend: Friend, completionHandler: (error: NSError?) -> Void) {
        
    }
    func updateCityForUserId(id: String, city: CityFull, completionHandler: (error: NSError?) -> Void) {
        
    }
    func addBarFeedForUserId(id: String, barFeed: BarFeed, completionHandler: (error: NSError?) -> Void) {
        
    }
    func updateBarFeedForUserId(id: String, barFeed: BarFeed, completionHandler: (error: NSError?) -> Void) {
        
    }
    
    // MARK: - Bar
    func getBarForId(id: String, completionHandler: (bar: Bar?, error: NSError?) -> Void) {
        
    }
    func saveBar(bar: Bar, completionHandler: (error: NSError?) -> Void) {
        
    }
    func createBar(bar: Bar, completionHandler: (error: NSError?) -> Void) {
        
    }
    
    // MARK: - Bar Activity
    func getBarActivityForId(id: String, completionHandler: (user: User?, error: NSError?) -> Void) {
        
    }
    func saveBarActivity(barActivity: BarActivity, completionHandler: (error: NSError?) -> Void) {
        
    }
    func createBarActivity(barActivity: BarActivity, completionHandler: (error: NSError?) -> Void) {
        
    }
    
    // MARK: - City
    func getCityForId(id: String, completionHandler: (city: CityFull?, error: NSError?) -> Void) {
        
    }
    
    // MARK: - Specials
    func getSpecialsForBarId(id: String, completionHandler: (specials: [Special]?, error: NSError?) -> Void) {
        
    }
    
    // MARK: - Friend Request
    func getFriendRequestsForUserId(id: String, completionHandler: (friendRequest: [FriendRequest]?, error: NSError?) -> Void) {
        
    }
    func createFriendRequest(friendRequest: FriendRequest, completionHandler: (error: NSError?) -> Void) {
        
    }
    func deleteFriendRequestForId(id: String, completionHandler: (error: NSError?) -> Void) {
        
    }
    
}
