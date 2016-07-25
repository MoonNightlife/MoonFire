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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailText: UITextField!

    @IBOutlet weak var passwordText: UITextField!
    
    @IBOutlet weak var username: UITextField!
   
    @IBOutlet weak var retypePassword: UITextField!

    @IBOutlet weak var name: UITextField!
  
    @IBOutlet weak var maleOrFemale: UISegmentedControl!

    @IBOutlet weak var age: UITextField!

  
    @IBOutlet weak var cancelButton: UIButton!
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
    

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 700)
    }
    
    func setUpView(){
        
        //setting up the textfield delegates
        emailText.delegate = self
        passwordText.delegate = self
        retypePassword.delegate = self
        name.delegate = self
        age.delegate = self
        username.delegate = self
        
        //Cha
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordText.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        retypePassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        name.attributedPlaceholder = NSAttributedString(string:"Name", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        age.attributedPlaceholder = NSAttributedString(string:"Birthday", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        username.attributedPlaceholder = NSAttributedString(string:"Username", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        
        //scroll view
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
        
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
           // retypePassword.rightPlaceholder = "✅"
        } else {
            //retypePassword.rightPlaceholder = "❌"
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
        //emailText.rightPlaceholder = "xxx@xxx.xx"
        //passwordText.rightPlaceholder = "Min 5 Characters"
        //username.rightPlaceholder = "5-12 Characters"
      //  name.rightPlaceholder = "Max 18 Characters"
       // retypePassword.rightPlaceholder = "❌"
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
                    if name.characters.count < 18 && name.characters.count > 0 {
                        if age != "" {
                            // Check if username is free
                            SwiftOverlays.showBlockingWaitOverlayWithText("Creating User")
                            rootRef.child("users").queryOrderedByChild("username").queryEqualToValue(userName).observeSingleEventOfType(.Value, withBlock: { (snap) in
                                if snap.value is NSNull {
                                    // Creates the user
                                    FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (autData, error) in
                                        SwiftOverlays.removeAllBlockingOverlays()
                                        if error == nil {
                                            SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
                                            // Signs the user in
                                            FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (autData, error) in
                                                if error == nil {
                                                    NSUserDefaults.standardUserDefaults().setValue(autData!.uid, forKey: "uid")
                                                    let pictureString = createStringFromImage("default_pic.png")
                                                    let userInfo = ["name": name, "username": userName, "age": age, "gender": maleOrFemale, "email":email, "privacy":"off", "profilePicture": pictureString!]
                                                    currentUser.setValue(userInfo)
                                                    self.performSegueWithIdentifier("NewLogin", sender: nil)
                                                } else {
                                                    print(error)
                                                }
                                                SwiftOverlays.removeAllBlockingOverlays()

                                            })
                                        } else {
                                            if error!.code == -9 {
                                                self.displayAlertWithMessage("Email already taken")
                                            }
                                        }

                                    })
                                } else {
                                    SwiftOverlays.removeAllBlockingOverlays()
                                    self.displayAlertWithMessage("Username already exist.")
                                }
                            }) { (error) in
                                SwiftOverlays.removeAllBlockingOverlays()
                                print(error.description)
                            }
                        } else {
                            displayAlertWithMessage("Please enter a birthday")
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
    
    // Returns to the login page if cancel button is clicked
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
