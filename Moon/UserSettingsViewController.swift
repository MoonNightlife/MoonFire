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
            case 0:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["username": newInfo.text!])
                }
                alertView.showEdit("Update Username", subTitle: "This is how other users view you")
            case 1:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["name": newInfo.text!])
                }
                alertView.showEdit("Update Name", subTitle: "Changes name displayed on your profile")
            case 2:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["email": newInfo.text!])
                    //TODO: - update email for account
                }
                alertView.showEdit("Update Email", subTitle: "Changes your sign in email")
            case 3:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["age": newInfo.text!])
                }
                alertView.showEdit("Update Age", subTitle: "Age is not displayed to anyone")
            case 4:
                let newInfo = alertView.addTextField()
                alertView.addButton("Save") {
                    currentUser.updateChildValues(["gender": newInfo.text!])
                }
                alertView.showEdit("Update Gender", subTitle: "\"male\" or \"female\"")
            default: break
        }
     }

   }
}
