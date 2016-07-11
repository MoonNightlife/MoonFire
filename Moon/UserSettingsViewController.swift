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
    
    var loggingOut = false
    
    // MARK: - Actions
    
    // Logs the user out session and removes uid from local data store
    @IBAction func logout() {
        loggingOut = true
        currentUser.removeAllObservers()
        currentUser.unauth()
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
        let loginVC: LogInViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LogInViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }
    
    // Reset the password once the user clicks button in tableview
    @IBAction func changePassword() {
        
        // Setup alert view so user can enter information for password change
        let alertView = SCLAlertView()
        let oldPassword = alertView.addTextField("Old password")
        let newPassword = alertView.addTextField("New password")
        let retypedPassword = alertView.addTextField("Retype password")
       
        // Once the user selects the update firebase attempts to change password on server
        alertView.addButton("Update") {
            if retypedPassword.text == newPassword.text {
                self.showWaitOverlayWithText("Changing password")
                rootRef.changePasswordForUser(currentUser.authData.providerData["email"] as! String, fromOld: oldPassword.text, toNew: newPassword.text, withCompletionBlock: { (error) in
                    self.removeAllOverlays()
                    if error == nil {
                        
                    } else {
                        print(error.description)
                        self.displayAlertWithMessage("Can't update password, try again")
                    }
                })
            } else {
                self.displayAlertWithMessage("Password do not match")
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
        currentUser.observeEventType(.Value, withBlock: { snapshot in
            
            self.userName.detailTextLabel?.text = snapshot.value.objectForKey("username") as? String
            self.name.detailTextLabel?.text = snapshot.value.objectForKey("name") as? String
            self.email.detailTextLabel?.text = snapshot.value.objectForKey("email") as? String
            self.age.detailTextLabel?.text = snapshot.value.objectForKey("age") as? String
            self.gender.detailTextLabel?.text = snapshot.value.objectForKey("gender") as? String
            self.bio.detailTextLabel?.text = snapshot.value.objectForKey("bio") as? String
            self.favoriteDrinks.detailTextLabel?.text = snapshot.value.objectForKey("favoriteDrink") as? String
            self.privacy.detailTextLabel?.text = snapshot.value.objectForKey("privacy") as? String
            if !(snapshot.childSnapshotForPath("simLocation").value is NSNull) {
                self.city.detailTextLabel?.text = snapshot.childSnapshotForPath("simLocation").value["name"] as? String
            } else {
                self.city.detailTextLabel?.text = "Location Based"
            }
            
            self.tableView.reloadData()
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // Update the labels for the cells
        userName.textLabel?.text = "Username"
        name.textLabel?.text = "Name"
        email.textLabel?.text = "Email"
        age.textLabel?.text = "Age"
        gender.textLabel?.text = "Gender"
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove object that updates the users setting
        if !loggingOut {
            currentUser.removeAllObservers()
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
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["name": newInfo.text!])
                }
                alertView.showEdit("Update Name", subTitle: "This is how other users view you")
            case 2:
                let newInfo = alertView.addTextField("New email")
                let password = alertView.addTextField("Password")
                alertView.addButton("Save") {
                    self.showWaitOverlayWithText("Changing email")
                    // Updates the email account for user auth
                    rootRef.changeEmailForUser(currentUser.authData.providerData["email"] as! String, password: password.text!, toNewEmail: newInfo.text!, withCompletionBlock: { (error) in
                        self.removeAllOverlays()
                        if error == nil {
                            currentUser.updateChildValues(["email": newInfo.text!])
                        } else {
                            self.displayAlertWithMessage("Can't update email, check your password")
                        }
                    })
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
                alertView.addButton("Save", action: { 
                    currentUser.updateChildValues(["bio": newInfo.text!])
                })
                alertView.showEdit("Update Bio", subTitle: "People can see your bio when viewing your profile")
            case 6:
                let newInfo = alertView.addTextField("New Drink")
                alertView.addButton("Save", action: { 
                    currentUser.updateChildValues(["favoriteDrink": newInfo.text!])
                })
                alertView.showEdit("Update Drink", subTitle: "Your favorite drink will display on your profile, and help us find specials for you")
            case 7:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save", action: {
                    if newInfo.text?.lowercaseString == "on" || newInfo.text?.lowercaseString == "off" {
                        currentUser.updateChildValues(["privacy": newInfo.text!.lowercaseString])
                    } else {
                        self.displayAlertWithMessage("Not a valid input")
                    }
                })
                alertView.showEdit("Change Privacy", subTitle: "On or Off")
            case 8:
                var cityChoices = [City]()
                rootRef.childByAppendingPath("cities").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    for city in snap.children {
                        let city = City(image: nil, name: (city as! FDataSnapshot).value["name"] as? String, long: (city as! FDataSnapshot).value["long"] as? Double, lat: (city as! FDataSnapshot).value["lat"] as? Double)
                        cityChoices.append(city)
                        alertView.addButton(city.name!, action: {
                            print("Selected location")
                            currentUser.childByAppendingPath("simLocation").childByAppendingPath("long").setValue(city.long)
                            currentUser.childByAppendingPath("simLocation").childByAppendingPath("lat").setValue(city.lat)
                            currentUser.childByAppendingPath("simLocation").childByAppendingPath("name").setValue(city.name)
                        })
                    }
                    alertView.addButton("Location Based", action: { 
                        currentUser.childByAppendingPath("simLocation").removeValue()
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
