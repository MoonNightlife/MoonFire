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
import FBSDKLoginKit
import GoogleSignIn

class UserSettingsViewController: UITableViewController {
    
    // Apperences used with SCLAlertViews to fit moon's theme
    // To see full list of options go to the SCLAlertView pod file
    let editFieldApperance = SCLAlertView.SCLAppearance(
        kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
        kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
        kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
        showCircularIcon: false,
        showCloseButton: true,
        contentViewBorderColor: UIColor.redColor(),
        titleColor: UIColor.redColor()
    )
    let deleteAccountApperance = SCLAlertView.SCLAppearance(
        kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
        kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
        kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
        showCircularIcon: false,
        showCloseButton: true,
        contentViewBorderColor: UIColor.redColor(),
        titleColor: UIColor.redColor()
    )
    
    var handles = [UInt]()

    // MARK: - Outlets
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
    
    @IBAction func privacyChanged(sender: UISwitch) {
        if sender.on == true {
            currentUser.updateChildValues(["privacy": true])
        } else {
            currentUser.updateChildValues(["privacy": false])
        }
    }
    
    @IBOutlet weak var privacySwitch: UISwitch!
    // MARK: - Actions
    @IBAction func logout() {
        
        SwiftOverlays.showBlockingWaitOverlayWithText("Logging Out")
        if FIRAuth.auth()?.currentUser?.providerData != nil {
            GIDSignIn.sharedInstance().signOut()
            FBSDKLoginManager().logOut()
        }
        // Logs the user out and removes uid from local data store
        try! FIRAuth.auth()!.signOut()
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
        let loginVC: LogInViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LogInViewController
        SwiftOverlays.removeAllBlockingOverlays()
        self.presentViewController(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func deleteUserAccount(sender: AnyObject) {
        let alertView = SCLAlertView(appearance: self.deleteAccountApperance)
        checkProviderForCurrentUser(self) { (type) in
            if type == .Facebook || type == .Google {
                alertView.addButton("Delete") {
                    SwiftOverlays.showBlockingWaitOverlayWithText("Deleting Account")
                    
                            self.unAuthForFacebookOrGoogle(type, handler: { (error) in
                                self.finishDeletingAccount(error)
                            })
                   
                }
                alertView.showNotice("Delete Account", subTitle: "Are you sure you want to delete your account?")
            } else {
                let email = alertView.addTextField("Email")
                email.autocapitalizationType = .None
                let password = alertView.addTextField("Password")
                password.secureTextEntry = true
                alertView.addButton("Delete") {
                    SwiftOverlays.showBlockingWaitOverlayWithText("Deleting Account")
                    self.seeIfUserIsDeleteingCurrentlyLoginAccount(email.text!, handler: { (isTrue) in
                        if isTrue {
                           
                                    self.unAuthUserForEmail(email.text!, password: password.text!, handler: { (error) in
                                        self.finishDeletingAccount(error)
                                    })
                                    
                             
                        }
                    })
                }
                alertView.showNotice("Delete Account", subTitle: "Please enter your username and password to delete your account.")
            }
        }

    }
    
    func finishDeletingAccount(error: NSError?) {
        if error == nil {
            self.removeFriendRequestForUserID(currentUser.key)
            self.getUserNameForCurrentUser({ (username) in
                if username != nil {
                    self.removeFriendRequestSentOutByUserName(username!, handler: { (didDelete) in
                        if didDelete {
                            self.removeBarActivityAndDecrementBarCountForCurrentUser({ (didDelete) in
                                if didDelete {
                                    self.removeCurrentUserFromFriendsListAndBarFeedOfOtherUsers(username!, handler: { (didDelete) in
                                        if didDelete {
                                            
                                            SwiftOverlays.removeAllBlockingOverlays()
                                            // Remove user information from database
                                            rootRef.child("users").child(currentUser.key).removeAllObservers()
                                            rootRef.child("users").child(currentUser.key).removeValue()
                                            let loginVC: LogInViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LogInViewController
                                            self.presentViewController(loginVC, animated: true, completion: nil)
                                            
                                        }
                                    })
                                }
                            })
                        }
                    })
                }
            })
        }
    }

    
    @IBAction func changePassword() {
        // Reset the password once the user clicks button in tableview
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
                        showAppleAlertViewWithText(error.description, presentingVC: self)
                    }
                })
            } else {
                SCLAlertView().showError("Can't reset password", subTitle: "Make sure both passwords are the same, and that it is at least 5 characters in length")
            }
        }
        // Display the edit alert
        alertView.showEdit("Change password", subTitle: "")
    }
    
    // MARK: - Helper functions for deleting an account
    func seeIfUserIsDeleteingCurrentlyLoginAccount(email: String, handler: (isTrue: Bool)->()) {
        // Check and make sure user is deleteing the account he is signed into
        if FIRAuth.auth()?.currentUser?.email == email.lowercaseString {
            handler(isTrue: true)
        } else {
            SwiftOverlays.removeAllBlockingOverlays()
            SCLAlertView().showError("Could Not Delete", subTitle: "Verify you are signed into the account you are trying to delete")
            handler(isTrue: false)
        }
    }
    
    func removeFriendRequestForUserID(ID:String) {
        // Remove any friend request for that user
        rootRef.child("friendRequest").child(ID).removeValue()
    }
    
    func unAuthForFacebookOrGoogle(type: Provider, handler: (error: NSError?) -> ()) {
        var credentials: FIRAuthCredential!
        if type == Provider.Google {
            let authentication = GIDSignIn.sharedInstance().currentUser.authentication
            credentials = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                      accessToken: authentication.accessToken)
        } else if type == Provider.Facebook {
            credentials = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        }
        FIRAuth.auth()?.currentUser?.reauthenticateWithCredential(credentials, completion: { (error) in
            if let error = error {
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                self.deleteProfilePictureForUser(currentUser.key, handler: { (didDelete) in
                    if didDelete {
                        FIRAuth.auth()?.currentUser?.deleteWithCompletion({ (error) in
                            if let error = error {
                                SwiftOverlays.removeAllBlockingOverlays()
                                SCLAlertView().showError("Could Not Delete", subTitle: "")
                                showAppleAlertViewWithText(error.description, presentingVC: self)
                                handler(error: error)
                            } else {
                                if type == .Google {
                                    GIDSignIn.sharedInstance().signOut()
                                } else if type == .Facebook {
                                    FBSDKLoginManager().logOut()

                                }
                                handler(error: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func unAuthUserForEmail(email: String, password: String, handler: (error: NSError?) -> ()) {
        // Sign the user in again before deleting account because the method "deleteWithCompletion" requires it
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            if let error = error {
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                self.deleteProfilePictureForUser(currentUser.key, handler: { (didDelete) in
                    if didDelete {
                        FIRAuth.auth()?.currentUser?.deleteWithCompletion({ (error) in
                            if let error = error {
                                SwiftOverlays.removeAllBlockingOverlays()
                                SCLAlertView().showError("Could Not Delete", subTitle: "")
                                showAppleAlertViewWithText(error.description, presentingVC: self)
                                handler(error: error)
                                
                            } else {
                                handler(error: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func getUserNameForCurrentUser(handler: (username: String?) -> ()) {
        // Get username for current user
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let username = snap.value {
                handler(username: username as? String)
            } else {
                SwiftOverlays.removeAllBlockingOverlays()
                handler(username: nil)
            }
            }) { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(username: nil)
        }
    }
    
    func removeBarActivityAndDecrementBarCountForCurrentUser(handler: (didDelete: Bool) -> ()) {
        // Decrement user if they are going to a bar
        currentUser.child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull),let currentBar = snap.value {
                decreamentUsersGoing(rootRef.child("bars").child(currentBar as! String))
                // Remove bar activity
                rootRef.child("barActivities").child(currentUser.key).removeValue()
            }
            handler(didDelete: true)
            }) { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func removeCurrentUserFromFriendsListAndBarFeedOfOtherUsers(username: String, handler: (didDelete: Bool) -> ()) {
        // Grabs all the friends the current user has and deletes the current users presence from other users friends list and bar feed
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for user in snap.children {
                if !(user is NSNull) {
                    let user = user as! FIRDataSnapshot
                    rootRef.child("users").child(user.value as! String).child("friends").child(username).removeValue()
                    rootRef.child("users").child(user.value as! String).child("barFeed").child(currentUser.key).removeValue()
                }
            }
            handler(didDelete: true)
            }) { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func removeFriendRequestSentOutByUserName(username: String, handler: (didDelete: Bool) -> ()) {
        rootRef.child("friendRequest").queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { (snap) in
            for userHolder in snap.children {
                let userHolder = userHolder as! FIRDataSnapshot
                for user in userHolder.children {
                    let user = user as! FIRDataSnapshot
                    if username == user.key {
                        user.ref.removeValue()
                    }
                }
            }
            handler(didDelete: true)
            }) { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func deleteProfilePictureForUser(Id: String, handler:(didDelete: Bool) -> ()) {
        // Delete the file
        storageRef.child("profilePictures").child(currentUser.key).child("userPic").deleteWithCompletion { (error) -> Void in
            if let error = error {
                handler(didDelete: false)
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                handler(didDelete: true)
            }
        }
    }
    
    


    // MARK: - View controller lifecycle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "Settings"
        
        // Grabs all the user settings and reloads the table view
        showWaitOverlay()
        getUserSettings()
        setUpNavigation()
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
    
    //MARK: - Helper functions for view
    func getUserSettings() {
        let handle = currentUser.observeEventType(.Value, withBlock: { (snap) in
            if let userInfo = snap.value {
                self.userName.detailTextLabel?.text = userInfo["username"] as? String
                self.name.detailTextLabel?.text = userInfo["name"] as? String
                self.email.detailTextLabel?.text = userInfo["email"] as? String
                self.age.detailTextLabel?.text = userInfo["age"] as? String
                self.gender.detailTextLabel?.text = userInfo["gender"] as? String
                self.bio.detailTextLabel?.text = userInfo["bio"] as? String
                self.favoriteDrinks.detailTextLabel?.text = userInfo["favoriteDrink"] as? String
                if userInfo["privacy"] as? String == "off" {
                    self.privacySwitch.on = false
                } else {
                    self.privacySwitch.on = true
                }
            }
            if let simLoc = snap.childSnapshotForPath("simLocation").value {
                self.city.detailTextLabel?.text = simLoc["name"] as? String
            } else {
                self.city.detailTextLabel?.text = "Location Based"
            }
            self.removeAllOverlays()
            self.tableView.reloadData()
        }) { (error) in
            self.removeAllOverlays()
            showAppleAlertViewWithText(error.description, presentingVC: self)
        }
        handles.append(handle)
    }
    
    //MARK: - Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Show popup for editing
        let alertView = SCLAlertView(appearance: editFieldApperance)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0: break

            case 1: break
//                let newInfo = alertView.addTextField()
//                newInfo.autocapitalizationType = .None
//                alertView.addButton("Save") {
//                    currentUser.updateChildValues(["name": newInfo.text!])
//                }
//                alertView.showEdit("Update Name", subTitle: "This is how other users view you")
            case 2: 
            DatePickerDialog().show("Update age", doneButtonTitle: "Save", cancelButtonTitle: "Cancel", defaultDate: NSDate(), datePickerMode: .Date, callback: { (date) in
                
                let dateFormatter = NSDateFormatter()
                
                dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                
                dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
                
                currentUser.updateChildValues(["age":dateFormatter.stringFromDate(date)])
            })
            case 3:
                let pickerData = [
                    ["value": "male", "display": "Male"],
                    ["value": "female", "display": "Female"]
                ]
                PickerDialog().show("Select gender", doneButtonTitle: "Apply", cancelButtonTitle: "Cancel", options: pickerData, selected: nil, callback: { (value) in
                    currentUser.updateChildValues(["gender": value])
                })
               
//                let newInfo = alertView.addTextField()
//                newInfo.autocapitalizationType = .None
//                alertView.addButton("Save") {
//                    if newInfo.text?.lowercaseString == "male" || newInfo.text?.lowercaseString == "female" {
//                        currentUser.updateChildValues(["gender": newInfo.text!.lowercaseString])
//                    } else {
//                        displayAlertWithMessage("Not a valid input")
//                    }
//                }
//                alertView.showEdit("Update Gender", subTitle: "\"Male\" or \"Female\"")
            case 4:
                let newInfo = alertView.addTextField("New email")
                newInfo.autocapitalizationType = .None
                alertView.addButton("Save") {
                    self.showWaitOverlayWithText("Changing email")
                    // Updates the email account for user auth
                    if isValidEmail(newInfo.text!) {
                        FIRAuth.auth()?.currentUser?.updateEmail(newInfo.text!, completion: { (error) in
                            self.removeAllOverlays()
                            if error != nil {
                                currentUser.updateChildValues(["email": newInfo.text!])
                            } else {
                                showAppleAlertViewWithText(error!.description, presentingVC: self)
                            }
                        })
                    } else {
                        displayAlertWithMessage("Make sure text is valid email")
                    }
                }
                alertView.showEdit("Update Email", subTitle: "Changes your sign in email")
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
            case 7: break
//                let newInfo = alertView.addTextField()
//                newInfo.autocapitalizationType = .None
//                alertView.addButton("Save", action: {
//                    if newInfo.text?.lowercaseString == "on" || newInfo.text?.lowercaseString == "off" {
//                        currentUser.updateChildValues(["privacy": newInfo.text!.lowercaseString])
//                    } else {
//                        displayAlertWithMessage("Not a valid input")
//                    }
//                })
//                alertView.showEdit("Update Privacy", subTitle: "On or Off")
            case 8:
                var cityChoices = [City]()
                SwiftOverlays.showBlockingWaitOverlayWithText("Grabbing Cities")
                rootRef.child("cities").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    for city in snap.children {
                        // Using the city stuct for convience, so the image is going to be set to nil
                        let city = City(image: nil, name: (city as! FIRDataSnapshot).value!["name"] as? String, long: (city as! FIRDataSnapshot).value!["long"] as? Double, lat: (city as! FIRDataSnapshot).value!["lat"] as? Double)
                        cityChoices.append(city)
                        alertView.addButton(city.name!, action: {
                            currentUser.child("simLocation").child("long").setValue(city.long)
                            currentUser.child("simLocation").child("lat").setValue(city.lat)
                            currentUser.child("simLocation").child("name").setValue(city.name)
                        })
                    }
                    alertView.addButton("Location Based", action: {
                        // Once the location simLocation is removed the rest of the app will use the gps location when if finds nil
                        currentUser.child("simLocation").removeValue()
                    })
                    SwiftOverlays.removeAllBlockingOverlays()
                    alertView.showEdit("Change City", subTitle: "Pick a city below")
                    }, withCancelBlock: { (error) in
                        SwiftOverlays.removeAllBlockingOverlays()
                        showAppleAlertViewWithText(error.description, presentingVC: self)
                })
            default: break
        }
     }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
   }
}

