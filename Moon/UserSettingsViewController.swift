//
//  UserSettingsViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/18/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase
import SCLAlertView
import SwiftOverlays

class UserSettingsViewController: UITableViewController {

    // MARK: - Outlets
    
    var handles = [UInt]()
    
    @IBOutlet weak var userName: UITableViewCell!
    @IBOutlet weak var name: UITableViewCell!
    @IBOutlet weak var email: UITableViewCell!
    @IBOutlet weak var age: UITableViewCell!
    @IBOutlet weak var gender: UITableViewCell!
    @IBOutlet weak var bio: UITableViewCell!
    @IBOutlet weak var favoriteDrinks: UITableViewCell!
    @IBOutlet weak var phoneNumber: UITableViewCell!
    @IBOutlet weak var city: UITableViewCell!
    @IBOutlet weak var privacy: UITableViewCell!
    
  
    
    // MARK: - Actions
    
    // Logs the user out session and removes uid from local data store
    @IBAction func logout() {
        try! FIRAuth.auth()!.signOut()
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
        let loginVC: LogInViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LogInViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func deleteUserAccount(sender: AnyObject) {
//        let alertView = SCLAlertView()
//        let email = alertView.addTextField("Email")
//        email.autocapitalizationType = .None
//        let password = alertView.addTextField("Password")
//        password.secureTextEntry = true
//        alertView.addButton("Delete") {
//            self.seeIfUserIsDeleteingCurrentlyLoginAccount(email.text!, handler: { (isTrue) in
//                if isTrue {
//                    self.unAuthUserForEmail(email.text!, password: password.text!, handler: { (error) in
//                        if error == nil {
//                            self.removeFriendRequestForUserID(currentUser.key)
//                            self.getUserNameForCurrentUser({ (username) in
//                                if self.userName != nil {
//                                    self.removeBarActivityAndDecrementBarCountForCurrentUser({ (didDelete) in
//                                        if didDelete {
//                                            self.removeCurrentUserFromFriendsListOfOtherUsers(username!, handler: { (didDelete) in
//                                                if didDelete {
//                                                    // Remove user information from database
//                                                    rootRef.childByAppendingPath("users").childByAppendingPath(currentUser.key).removeAllObservers()
//                                                    rootRef.childByAppendingPath("users").childByAppendingPath(currentUser.key).removeValue()
//                                                    self.loggingOut = true
//                                                    let loginVC: LogInViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LogInViewController
//                                                    self.presentViewController(loginVC, animated: true, completion: nil)
//                                                }
//                                            })
//                                        }
//                                    })
//                                }
//                            })
//                        }
//                    })
//                }
//            })
//        }
//        alertView.showNotice("Delete Account", subTitle: "Please enter your username and password to delete your account")
    }
    
    // MARK: - Helper Functions for deleting an account
    func seeIfUserIsDeleteingCurrentlyLoginAccount(email: String, handler: (isTrue: Bool)->()) {
        // Check and make sure user is deleteing the account he is signed into
        currentUser.child("email").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) && (snap.value as! String == email.lowercaseString) {
                handler(isTrue: true)
            } else {
                SCLAlertView().showError("Could Not Delete", subTitle: "Verify you are signed into the account you are trying to delete")
                handler(isTrue: false)
            }
        })
    }
    
    func removeFriendRequestForUserID(ID:String) {
        // Remove any friend request for that user
        rootRef.child("friendRequest").child(ID).removeValue()
    }
    
    func unAuthUserForEmail(email: String, password: String, handler: (error: NSError?) -> ()) {
        // If user entered the correct email for current account continue with deleting the account
        FIRAuth.auth()?.currentUser?.deleteWithCompletion({ (error) in
            if error == nil {
                handler(error: nil)
            } else {
                SCLAlertView().showError("Could Not Delete", subTitle: "")
                handler(error: error)
            }
        })
    }
    
    func getUserNameForCurrentUser(handler: (username: String?) -> ()) {
        // Get username for current user
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                handler(username: snap.value as? String)
            } else {
                handler(username: nil)
            }
        })
    }
    
    func removeBarActivityAndDecrementBarCountForCurrentUser(handler: (didDelete: Bool) -> ()) {
        // Decrement user if they are going to a bar
        currentUser.child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                decreamentUsersGoing(rootRef.child("bars").child(snap.value as! String))
                // Remove bar activity
                rootRef.child("barActivities").child(currentUser.key).removeValue()
            }
            handler(didDelete: true)
        })
    }
    
    func removeCurrentUserFromFriendsListOfOtherUsers(username: String, handler: (didDelete: Bool) -> ()) {
        // Remove user from friends list of other users
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for user in snap.children {
                if !(user is NSNull) {
                    let user = user as! FIRDataSnapshot
                    rootRef.child("users").child(user.value as! String).child("friends").child(username).removeValue()
                }
            }
            handler(didDelete: true)
        })
    }
    

    // Reset the password once the user clicks button in tableview
    @IBAction func changePassword() {
        
        // Setup alert view so user can enter information for password change
        let alertView = SCLAlertView()
        let newPassword = alertView.addTextField("New password")
        newPassword.autocapitalizationType = .None
        newPassword.secureTextEntry = true
        let retypedPassword = alertView.addTextField("Retype password")
        retypedPassword.autocapitalizationType = .None
        retypedPassword.secureTextEntry = true
       
        // Once the user selects the update firebase attempts to change password on server
        alertView.addButton("Update") {
            let user = FIRAuth.auth()?.currentUser
            if user != nil && newPassword.text == retypedPassword.text && newPassword.text?.characters.count > 4{
                self.showWaitOverlayWithText("Changing password")
                FIRAuth.auth()?.currentUser?.updatePassword(newPassword.text!, completion: { (error) in
                    self.removeAllOverlays()
                    if let error = error {
                        print(error.description)
                         self.displayAlertWithMessage("Can't update password, try again")
                    } else {
                        
                    }
                })
            } else {
                self.displayAlertWithMessage("Can't reset password right now, check the length")
            }
        }
        
        // Display the edit alert
        alertView.showEdit("Change password", subTitle: "")
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "Settings"
        
        // Grabs all the user settings and reloads the table view
        let handle = currentUser.observeEventType(.Value, withBlock: { snapshot in
            
            self.userName.detailTextLabel?.text = snapshot.value!.objectForKey("username") as? String
            self.name.detailTextLabel?.text = snapshot.value!.objectForKey("name") as? String
            self.email.detailTextLabel?.text = snapshot.value!.objectForKey("email") as? String
            self.age.detailTextLabel?.text = snapshot.value!.objectForKey("age") as? String
            self.gender.detailTextLabel?.text = snapshot.value!.objectForKey("gender") as? String
            self.bio.detailTextLabel?.text = snapshot.value!.objectForKey("bio") as? String
            self.favoriteDrinks.detailTextLabel?.text = snapshot.value!.objectForKey("favoriteDrink") as? String
            self.privacy.detailTextLabel?.text = snapshot.value!.objectForKey("privacy") as? String
            if !(snapshot.childSnapshotForPath("simLocation").value is NSNull) {
                self.city.detailTextLabel?.text = snapshot.childSnapshotForPath("simLocation").value!["name"] as? String
            } else {
                self.city.detailTextLabel?.text = "Location Based"
            }
            
            self.tableView.reloadData()
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        handles.append(handle)
        // Update the labels for the cells
        userName.textLabel?.text = "Username"
        name.textLabel?.text = "Name"
        email.textLabel?.text = "Email"
        age.textLabel?.text = "Age"
        gender.textLabel?.text = "Gender"
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
            for handle in handles {
                rootRef.removeObserverWithHandle(handle)
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UINavigationBar.appearance().tintColor = UIColor.darkGrayColor()
    }
    
    //MARK: - Table View Delegate Methods
    
    // Show popup for editing
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alertView = SCLAlertView()
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0: break

            case 1:
                let newInfo = alertView.addTextField()
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["name": newInfo.text!])
                }
                alertView.showEdit("Update Name", subTitle: "This is how other users view you")
            case 2:
                let newInfo = alertView.addTextField("New email")
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save") {
                    self.showWaitOverlayWithText("Changing email")
                    // Updates the email account for user auth
                    if isValidEmail(newInfo.text!) {
                        FIRAuth.auth()?.currentUser?.updateEmail(newInfo.text!, completion: { (error) in
                            self.removeAllOverlays()
                            if error == nil {
                                currentUser.updateChildValues(["email": newInfo.text!])
                            } else {
                                self.displayAlertWithMessage("Can't update email, check your password")
                            }
                        })
                    } else {
                        self.displayAlertWithMessage("Make sure text is valid email")
                    }
                }
                alertView.showEdit("Update Email", subTitle: "Changes your sign in email")
            case 3:
                
                DatePickerDialog().show("Update age", doneButtonTitle: "Save", cancelButtonTitle: "Cancel", defaultDate: NSDate(), datePickerMode: .Date, callback: { (date) in
                    
                    let dateFormatter = NSDateFormatter()
                    
                    dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                    
                    dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
                    
                    currentUser.updateChildValues(["age":dateFormatter.stringFromDate(date)])
                })
                
            case 4:
                let newInfo = alertView.addTextField()
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save") {
                    if newInfo.text?.lowercaseString == "male" || newInfo.text?.lowercaseString == "female" {
                        currentUser.updateChildValues(["gender": newInfo.text!.lowercaseString])
                    } else {
                        self.displayAlertWithMessage("Not a valid input")
                    }
                }
                alertView.showEdit("Update Gender", subTitle: "\"Male\" or \"Female\"")
            case 5:
                let newInfo = alertView.addTextField("New Bio")
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save", action: { 
                    currentUser.updateChildValues(["bio": newInfo.text!])
                })
                alertView.showEdit("Update Bio", subTitle: "People can see your bio when viewing your profile")
            case 6:
                let newInfo = alertView.addTextField("New Drink")
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save", action: { 
                    currentUser.updateChildValues(["favoriteDrink": newInfo.text!])
                })
                alertView.showEdit("Update Drink", subTitle: "Your favorite drink will display on your profile, and help us find specials for you")
            case 7:
                let newInfo = alertView.addTextField()
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save", action: {
                    if newInfo.text?.lowercaseString == "on" || newInfo.text?.lowercaseString == "off" {
                        currentUser.updateChildValues(["privacy": newInfo.text!.lowercaseString])
                    } else {
                        self.displayAlertWithMessage("Not a valid input")
                    }
                })
                alertView.showEdit("Update Privacy", subTitle: "On or Off")
            case 8:
                var cityChoices = [City]()
                rootRef.child("cities").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    for city in snap.children {
                        let city = City(image: nil, name: (city as! FIRDataSnapshot).value!["name"] as? String, long: (city as! FIRDataSnapshot).value!["long"] as? Double, lat: (city as! FIRDataSnapshot).value!["lat"] as? Double)
                        cityChoices.append(city)
                        alertView.addButton(city.name!, action: {
                            print("Selected location")
                            currentUser.child("simLocation").child("long").setValue(city.long)
                            currentUser.child("simLocation").child("lat").setValue(city.lat)
                            currentUser.child("simLocation").child("name").setValue(city.name)
                        })
                    }
                    alertView.addButton("Location Based", action: { 
                        currentUser.child("simLocation").removeValue()
                    })
                    alertView.showEdit("Change City", subTitle: "Pick a city below")
                })
            default: break
        }
     }

   }
    
    // Displays an alert message with error as the title
    func displayAlertWithMessage(message:String) {
        SCLAlertView().showNotice("Error", subTitle: message)
    }

}
