//
//  CreateAccountViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import HTYTextField
import SwiftOverlays

class CreateAccountViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var emailText: HTYTextField!
    @IBOutlet weak var passwordText: HTYTextField!
    @IBOutlet weak var username: HTYTextField!
    @IBOutlet weak var retypePassword: HTYTextField!
    @IBOutlet weak var name: HTYTextField!
    @IBOutlet weak var maleOrFemale: UISegmentedControl!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var transView: UIView!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //translucent view set up
        transView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        transView.layer.cornerRadius = 5
        transView.layer.borderWidth = 1
        transView.layer.borderColor = UIColor.whiteColor().CGColor
        
        //buttons set up
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.cornerRadius = 5
        cancelButton.layer.borderColor = UIColor.whiteColor().CGColor
        cancelButton.tintColor = UIColor.whiteColor()
        
        createAccountButton.layer.borderWidth = 1
        createAccountButton.layer.cornerRadius = 5
        createAccountButton.layer.borderColor = UIColor.whiteColor().CGColor
        createAccountButton.tintColor = UIColor.whiteColor()
        
        //setting up the textfield delegates
        emailText.delegate = self
        passwordText.delegate = self
        retypePassword.delegate = self
        name.delegate = self
        age.delegate = self
        username.delegate = self

   
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
        
        //resigns the keyboards when it senses a touch
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        retypePassword.resignFirstResponder()
        name.resignFirstResponder()
        age.resignFirstResponder()
        username.resignFirstResponder()
        
    }
    
    //changes the status bar to white
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    //Resigns the keyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Adds the text to be displayed to the right of the label when user is typing
        emailText.rightPlaceholder = "xxx@xxx.xx"
        passwordText.rightPlaceholder = "6-12 Characters"
        username.rightPlaceholder = "6-12 Characters"
        retypePassword.rightPlaceholder = "6-12 Characters"
    }

    // MARK: - Creating and Canceling Actions
    
    // Creates an account for the user using their provided information
    @IBAction func createAccount(sender: UIButton) {
        
        // Populate vars with user data from label
        let userName = self.username.text!
        let email = emailText.text!
        let password = passwordText.text!
        let retypePassword = self.retypePassword.text!
        let name = self.name.text!
        let age = self.age.text!
        let maleOrFemale: String
        if self.maleOrFemale.selectedSegmentIndex == 0 {
            maleOrFemale = "male"
        } else {
            maleOrFemale = "female"
        }
        
        // Creates a new user and saves user info under the node /users/uid
        if email != "" && password != "" && retypePassword == password {
            // Creates the user
            SwiftOverlays.showBlockingWaitOverlayWithText("Creating User")
            rootRef.createUser(email, password: password, withValueCompletionBlock: { (error, autData) -> Void in
                SwiftOverlays.removeAllBlockingOverlays()
                if error == nil {
                    SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
                    // Signs the user in
                    rootRef.authUser(email, password: password, withCompletionBlock: { (error, autData) -> Void in
                        if error == nil {
                            NSUserDefaults.standardUserDefaults().setValue(autData.uid, forKey: "uid")
                            let userInfo = ["name": name, "username": userName, "age": age, "gender": maleOrFemale, "email":email]
                            currentUser.setValue(userInfo)
                            self.performSegueWithIdentifier("NewLogin", sender: nil)
                        } else {
                            print(error)
                        }
                        SwiftOverlays.removeAllBlockingOverlays()
                    })
                } else {
                    print(error)
                }
            })
        } else {
            // Alert user what the error was when attempting to create account
            if !(retypePassword == password) {
                let alert = UIAlertController(title: "Error", message: "Passwords do not match", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(action)
                presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "Enter email and password", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(action)
                presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Returns to the login page if cancel button is clicked
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
