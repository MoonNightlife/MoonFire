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
import FBSDKLoginKit
import GoogleSignIn

class LogInViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate {
    
    //MARK: - Properties

    var imageView: UIImageView?
    let scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
    var moveToLocation:CGFloat = 0
    var finishedScroll = false
    var stop = false
    var inMiddleOfLogin = false
    
    // MARK: - Outlets
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!

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
        
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["public_profile","email","user_friends"]
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        GIDSignIn.sharedInstance().signInSilently()
        
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
                if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil && !self.inMiddleOfLogin  {
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
                self.finishLogin(authData, error: error, type: .Firebase)
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
    
    // MARK: - Facebook login delegate methods
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError?) {
        if let error = error {
            showAppleAlertViewWithText(error.debugDescription, presentingVC: self)
        } else {
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                inMiddleOfLogin = true
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    self.finishLogin(user, error: error, type: .Facebook)
                }
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        // Logs the user out and removes uid from local data store
        try! FIRAuth.auth()!.signOut()
    }
    
    func finishLogin(authData: FIRUser?, error: NSError?, type: Provider) {
        
        if error == nil {
            // Save the user id locally
            NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: "uid")
            if let user = authData {
                // If the user didnt sign up with thier email then this will be nil and we should check and make sure the user is created in our database where we will then store the email address
                if user.email == nil {
                    for profile in user.providerData {
                        let name = profile.displayName
                        let email = profile.email
                        let photoURL = profile.photoURL
                        
                        var photo: NSData {
                            if let url = photoURL {
                                if let p = NSData(contentsOfURL: url) {
                                    return p
                                }
                            }
                            return UIImageJPEGRepresentation(UIImage(named: "default_pic.png")!, 0.1)!
                        }
            
                    
                        user.updateEmail(email!, completion: { (error) in
                            if let error = error {
                                GIDSignIn.sharedInstance().signOut()
                                FBSDKLoginManager().logOut()
                                SwiftOverlays.removeAllBlockingOverlays()
                                if error.code == 17007 {
                                    SCLAlertView().showError("Error", subTitle: "Email is already in use")
                                } else {
                                    showAppleAlertViewWithText(error.description, presentingVC: self)
                                }
                                user.deleteWithCompletion({ (error) in
                                    if let error = error {
                                        showAppleAlertViewWithText(error.description, presentingVC: self)
                                    }
                                })
                            } else {
                                checkIfUserIsInFirebase(email!, vc: self, handler: { (isUser) in
                                    self.promptForUserName({ (username) in
                                        if let username = username, let name = name, let email = email {
                                        storageRef.child("profilePictures").child((FIRAuth.auth()?.currentUser?.uid)!).child("userPic").putData(photo, metadata: nil) { (metaData, error) in
                                                if let error = error {
                                                    showAppleAlertViewWithText(error.description, presentingVC: self)
                                                } else {
                                                    let userInfo = ["name": name, "username": username, "email":email, "privacy":"off", "provider":type.rawValue]
                                                    currentUser.setValue(userInfo)
                                                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                                                }
                                            }
                                        } else {
                                            GIDSignIn.sharedInstance().signOut()
                                            FBSDKLoginManager().logOut()
                                            user.deleteWithCompletion({ (error) in
                                                if let error = error {
                                                    showAppleAlertViewWithText(error.description, presentingVC: self)
                                                }
                                            })
                                        }
                                    })
                                })
                            }
                        })
                    }
                } else {
                    SwiftOverlays.removeAllBlockingOverlays()
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                }
            }
        } else {
            showAppleAlertViewWithText(error!.description, presentingVC: self)
        }
    }
    
    func promptForUserName(handler: (username:String?) -> ()) {
        let apperance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alert = SCLAlertView(appearance: apperance)
        let usernameTextField = alert.addTextField("username")
        usernameTextField.autocapitalizationType = .None
        
        alert.addButton("Apply") {
            checkIfValidUsername(usernameTextField.text!, vc: self, handler: { (isValid) in
                if isValid {
                    print(usernameTextField.text!)
                    handler(username: usernameTextField.text!)
                } else {
                    let error = SCLAlertView(appearance: apperance)
                    error.addButton("Ok", action: {
                        self.promptForUserName({ (username) in
                            handler(username: username)
                        })
                    })
                    error.showError("Error", subTitle: "Username isn't right length, contains whitespace, or is already in use")
                }
            })
        }
        alert.addButton("Cancel") {
            handler(username: nil)
        }
        SwiftOverlays.removeAllBlockingOverlays()
        alert.showInfo("Enter a moon username", subTitle: "No whitespaces and 5-12 chars long")
    }
    
    // MARK: - Google login delegates
    // Implement the required GIDSignInDelegate methods
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
                withError error: NSError!) {
        if (error == nil) {
            // Auth with Firebase
            
            if let authentication = user.authentication {
                SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
                let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                             accessToken: authentication.accessToken)
                inMiddleOfLogin = true
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    self.finishLogin(user, error: error, type: .Google)
                }
            }
        } else {
            // Don't assert this error it is commonly returned as nil
            print("\(error.localizedDescription)")
        }
    }
    // Implement the required GIDSignInDelegate methods
    // Unauth when disconnected from Google
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
                withError error: NSError!) {
        // Logs the user out and removes uid from local data store
        try! FIRAuth.auth()!.signOut()
    }
    
}

extension FBSDKLoginButton {
    
}
