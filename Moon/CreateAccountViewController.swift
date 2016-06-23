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
import Firebase
import SCLAlertView

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
        cancelButton.backgroundColor = UIColor.clearColor()
        
        createAccountButton.layer.borderWidth = 1
        createAccountButton.layer.cornerRadius = 5
        createAccountButton.layer.borderColor = UIColor.whiteColor().CGColor
        createAccountButton.tintColor = UIColor.whiteColor()
        createAccountButton.backgroundColor = UIColor.clearColor()
        
        //setting up the textfield delegates
        emailText.delegate = self
        passwordText.delegate = self
        retypePassword.delegate = self
        name.delegate = self
        age.delegate = self
        username.delegate = self

    }
    
    @IBAction func ageEditingStarted(sender: UITextField) {
        let datePickerView:UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        
        sender.inputView = datePickerView
        
        datePickerView.addTarget(self, action: #selector(CreateAccountViewController.datePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        age.text = dateFormatter.stringFromDate(sender.date)
        
    }
    
    @IBAction func updateRetypePasswordLabel(sender: AnyObject) {
        if passwordText.text == retypePassword.text {
            retypePassword.rightPlaceholder = "✅"
        } else {
            retypePassword.rightPlaceholder = "❌"
        }
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
        passwordText.rightPlaceholder = "Min 5 Characters"
        username.rightPlaceholder = "5-12 Characters"
        name.rightPlaceholder = "Max 18 Characters"
        retypePassword.rightPlaceholder = "❌"
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
        if password.characters.count >= 5 && retypePassword == password {
            if isValidEmail(email) {
                if userName.characters.count >= 5 && userName.characters.count <= 12 {
                    if name.characters.count < 18 {
                        if age != "" {
                            // Check if username is free
                            SwiftOverlays.showBlockingWaitOverlay()
                            rootRef.childByAppendingPath("users").queryOrderedByChild("username").queryEqualToValue(userName).observeEventType(.Value, withBlock: { (snap) in
                                if snap.value is NSNull {
                                    // Creates the user
                                    SwiftOverlays.removeAllBlockingOverlays()
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
                                    SwiftOverlays.removeAllBlockingOverlays()
                                    self.displayAlertWithMessage("Username already exist.")
                                }
                            }) { (error) in
                                print(error.description)
                            }
                        } else {
                            displayAlertWithMessage("Please enter an age")
                        }
                    } else {
                        displayAlertWithMessage("Please enter a name")
                    }
                } else {
                    displayAlertWithMessage("Username is not correct amount of characters.")
                }
            } else {
                displayAlertWithMessage("Not a valid email.")
            }
        } else {
            // Alert user what the error was when attempting to create account
            if !(retypePassword == password) {
                displayAlertWithMessage("Passwords do not match.")
            } else {
               displayAlertWithMessage("Password is not the correct amount of characters.")
            }
        }
    }
    
    func displayAlertWithMessage(message:String) {
        SCLAlertView().showNotice("Error", subTitle: message)
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // println("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    // Returns to the login page if cancel button is clicked
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
