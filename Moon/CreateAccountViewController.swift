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
    
    // MARK: - Actions
    @IBAction func ageEditingStarted(sender: UITextField) {
        
        let datePickerView:UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        
        sender.inputView = datePickerView
        
        datePickerView.addTarget(self, action: #selector(CreateAccountViewController.datePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    @IBAction func updatePasswordLabel(sender: AnyObject) {
        checkIfPasswordsMatch()
    }
    
    @IBAction func updateRetypePasswordLabel(sender: AnyObject) {
        checkIfPasswordsMatch()
    }
    
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func createAccount(sender: UIButton) {
        //TODO: Move validation to the user model
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
                checkIfValidUsername(userName, vc: self, handler: { (isValid) in
                    if isValid {
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
                                                        FIRAuth.auth()?.currentUser?.sendEmailVerificationWithCompletion({ (error) in
                                                            if let error = error {
                                                                print(error.description)
                                                            } else {
                                                                
                                                            }
                                                        })
                                                        NSUserDefaults.standardUserDefaults().setValue(autData!.uid, forKey: "uid")
                                                        // Save image to firebase storage
                                                        let imageData = UIImageJPEGRepresentation(UIImage(named: "default_pic.png")!, 0.1)
                                                        if let data = imageData {
                                                            storageRef.child("profilePictures").child((FIRAuth.auth()?.currentUser?.uid)!).child("userPic").putData(data, metadata: nil) { (metaData, error) in
                                                                if let error = error {
                                                                    showAppleAlertViewWithText(error.description, presentingVC: self)
                                                                } else {
                                                                    let userInfo = ["name": name, "username": userName, "age": age, "gender": maleOrFemale, "email":email, "privacy":false,"provider":"Firebase"]
                                                                    currentUser.setValue(userInfo)
                                                                    SwiftOverlays.removeAllBlockingOverlays()
                                                                    self.performSegueWithIdentifier("NewLogin", sender: nil)
                                                                }
                                                            }
                                                        } else {
                                                            showAppleAlertViewWithText("error with deafult image", presentingVC: self)
                                                        }
                                                    } else {
                                                        print(error)
                                                    }
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
                                self.displayAlertWithMessage("Please enter a birthday")
                            }
                        } else {
                            self.displayAlertWithMessage("Please enter a name")
                        }
                    } else {
                        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
                        alertView.showNotice("Error", subTitle: "Username isn't right length, contains whitespace, contains invaild characters, or is already in use")
                        
                    }
                })
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

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 700)
    }
    
    // MARK: - Helper functions for view
    func setUpView(){
        
        // Setting up the textfield delegates
        emailText.delegate = self
        passwordText.delegate = self
        retypePassword.delegate = self
        name.delegate = self
        age.delegate = self
        username.delegate = self
        
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordText.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        retypePassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        name.attributedPlaceholder = NSAttributedString(string:"Name", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        age.attributedPlaceholder = NSAttributedString(string:"Birthday", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        username.attributedPlaceholder = NSAttributedString(string:"Username", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        
        // Scroll view
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scrollView.scrollEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
        
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        age.text = dateFormatter.stringFromDate(sender.date)
        
    }

    func checkIfPasswordsMatch() {
        if passwordText.text == retypePassword.text {
           // TODO: Show that passwords match
        } else {
            // TODO: Show that passwords dont match
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Changes the status bar to white
        return UIStatusBarStyle.LightContent
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Resigns the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Foreces the username to be lowercase when user is typing
        if textField.isEqual(username) {
            username.text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string.lowercaseString)
            return false
        }
        return true
    }

    func displayAlertWithMessage(message:String) {
        SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Error", subTitle: message)
    }

}
