//
//  LogInViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import SwiftOverlays
import HTYTextField
import SCLAlertView
import Firebase

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties

    var imageView: UIImageView?
    let scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
    var moveToLocation:CGFloat = 0
    var finishedScroll = false
    var stop = false
    
    // MARK: - Outlets

    //Constraints
    @IBOutlet weak var loginButtonViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomBaseDistanceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fbGoogleViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var logoDistance: NSLayoutConstraint!
    
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    
    //Objects
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSetUP()
        
    }
    
    func viewSetUP(){
        
        let screenHeight = self.view.frame.size.height
        
        //setting the textfield delegate
        emailText.delegate = self
        password.delegate = self
        
        
        //automatic scrolling of the image
        // NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(LogInViewController.scrolling), userInfo: nil, repeats: true)
        
        //login button set up 
        //loginButton.titleLabel!.font =  UIFont(name: "Roboto-Bold", size: screenHeight / 35.105)
        
        //email text field set up
        emailText.backgroundColor = UIColor.clearColor()
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        //password textfield set up
        password.backgroundColor = UIColor.clearColor()
        password.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        //constraints 
        logoHeight.constant = screenHeight / 7.172
        
        logoDistance.constant = screenHeight / 18.02
        
        bottomBaseDistanceConstraint.constant = screenHeight / 11.305

        //fbGoogleViewHeight.constant = screenHeight / 6.6
        
        loginButtonViewHeight.constant = screenHeight / 7.41
        
 
        
    }
    
    
    func scrolling() {
        
        if stop == false {
            
            if moveToLocation != 620 && finishedScroll == false{
                
                moveToLocation += 1
                
            } else {
                
                finishedScroll = true
            }
            
            if finishedScroll == true && moveToLocation != 4{
                
                moveToLocation -= 1
            } else {
                
                finishedScroll = false
            }
            
        }
        
        scrollView.setContentOffset(CGPointMake(moveToLocation, 0), animated: true)
        scrollView.layer.speed = 10
        
    }
    
    //Resigns the keyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
        
        //resigns the keyboards when it senses a touch 
        emailText.resignFirstResponder()
        password.resignFirstResponder()
        
    }
    
    //changes the status bar to white
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add text for the right of the label when the user has selected label
        //emailText.rightPlaceholder = "xxx@xxx.xx"
        //password.rightPlaceholder = "Min 5 Characters"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If the user is already logged in then perform the login
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if user != nil {
                if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil {
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                }
            } else {
                // No user is signed in.
            }
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func logUserIn(sender: UIButton) {
        
        self.view.endEditing(true)
        
        // Populate the properties with the user login credentials from labels
        let email = self.emailText.text
        let password = self.password.text
        
        // Log user in if the username and password isnt blank
        if email != "" && password != "" {
           SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
            FIRAuth.auth()?.signInWithEmail(email!, password: password!, completion: { (authData, error) in
                SwiftOverlays.removeAllBlockingOverlays()
                if error == nil {
                    // Save the user id locally
                    NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: "uid")
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                } else {
                    print(error)
                    let alertView = SCLAlertView()
                    let resetEmail = alertView.addTextField("Email")
                    resetEmail.text = email!
                    alertView.addButton("Rest password", action: {
                        self.resetPassword(resetEmail.text!)
                    })
                    alertView.showNotice("Error", subTitle: "If you can't remember your password you can reset it with your email")
                }

            })
        } else {
            // Alert the user if the email or password field is blank
            let alert = UIAlertController(title: "Error", message: "Enter email and password", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Functions
    
    func resetPassword(email: String) {
        FIRAuth.auth()?.sendPasswordResetWithEmail(email, completion: { (error) in
            if error != nil {
                self.displayAlertWithMessage("Could not send email")
            } else {
                SCLAlertView().showInfo("Email Sent", subTitle: "")
            }
        })
    }
    
    func displayAlertWithMessage(message:String) {
        SCLAlertView().showNotice("Error", subTitle: message)
    }
    
}
