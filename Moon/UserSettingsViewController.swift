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
                alertView.showEdit("Update Gender", subTitle: "\"male\" or \"female\"")
            default: break
        }
     }

   }
    
    // Displays an alert message with error as the title
    func displayAlertWithMessage(message:String) {
        SCLAlertView().showNotice("Error", subTitle: message)
    }

}
