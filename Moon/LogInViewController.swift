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

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Background Scrolling Variables
    
    var imageView: UIImageView?
    
    let scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
    
    var moveToLocation:CGFloat = 0
    var finishedScroll = false
    var stop = false
    
    // MARK: - Outlets
    

    @IBOutlet weak var emailText: HTYTextField!
    @IBOutlet weak var password: HTYTextField!
    @IBOutlet weak var transView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //setting the textfield delegate
        emailText.delegate = self
        password.delegate = self
        
        //adds the scroll view
        self.view.addSubview(scrollView)
        self.view.sendSubviewToBack(scrollView)
        
        scrollView.contentSize = CGSizeMake(1000, 1000)
        scrollView.scrollEnabled = false
        
        //sets backgroung
        let backgroundImage = UIImage(named: "dallas_skyline.jpeg")
        imageView = UIImageView(image: backgroundImage)
        imageView?.frame = CGRectMake(0, -100, 1000, 1000)
        scrollView.addSubview(imageView!)
        
        
        //automatic scrolling of the image
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(LogInViewController.scrolling), userInfo: nil, repeats: true)
        
        //translucent view set up
        transView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        transView.layer.cornerRadius = 5
        transView.layer.borderWidth = 1
        transView.layer.borderColor = UIColor.whiteColor().CGColor
        
        //buttons set up
        loginButton.layer.borderWidth = 1
        loginButton.layer.cornerRadius = 5
        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.tintColor = UIColor.whiteColor()
        
        createAccountButton.layer.borderWidth = 1
        createAccountButton.layer.cornerRadius = 5
        createAccountButton.layer.borderColor = UIColor.whiteColor().CGColor
        createAccountButton.tintColor = UIColor.whiteColor()
        

        

        
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
        emailText.rightPlaceholder = "xxx@xxx.xx"
        password.rightPlaceholder = "6-12 Characters"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If the user is already logged in then perform the login
        if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil && currentUser.authData != nil {
            self.performSegueWithIdentifier("LoggedIn", sender: nil)
        }
    }
    
    // MARK: - User Login and Logout Actions
    
    @IBAction func logUserIn(sender: UIButton) {
        
        // Populate the properties with the user login credentials from labels
        let email = self.emailText.text
        let password = self.password.text
        
        // Log user in if the username and password isnt blank
        if email != "" && password != "" {
           SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
            rootRef.authUser(email, password: password, withCompletionBlock: { (error, authData) -> Void in
                if error == nil {
                    // Save the user id locally
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                    print("Logged In")
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                } else {
                    print(error)
                }
                SwiftOverlays.removeAllBlockingOverlays()
            })
        } else {
            // Alert the user if the email or password field is blank
            let alert = UIAlertController(title: "Error", message: "Enter email and password", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
