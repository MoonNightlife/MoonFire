//
//  LogInViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import SwiftOverlays
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
    var usernameTextField: UITextField!
    
    // MARK: - Outlets
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    //MARK: - Actions
    @IBAction func forgotPasswordButton(sender: AnyObject) {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        let emailTextField = alertView.addTextField("Email")
        emailTextField.autocapitalizationType = .None
        alertView.addButton("Reset") {
            FIRAuth.auth()?.sendPasswordResetWithEmail(emailTextField.text!) { error in
                if let error = error {
                    showAppleAlertViewWithText(error.description, presentingVC: self)
                } else {
                    SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Email Sent", subTitle: "Check your email for further instructions")
                }
            }
        }
        alertView.showNotice("Reset Password", subTitle: "An email will be sent with instructions to reset your password")
    }
    
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
           let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
            alertView.showNotice("Error", subTitle: "Enter a password and email address")
        }
    }

  
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
      
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["public_profile","email","user_friends"]
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        viewSetUP()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // MARK: - Helper functions for view
    func viewSetUP(){
        
        // Scroll view set up
        scroll.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scroll.scrollEnabled = true
        scroll.backgroundColor = UIColor.clearColor()

        // Setting the textfield delegate
        emailText.delegate = self
        password.delegate = self
   
        // Email text field set up
        emailText.backgroundColor = UIColor.clearColor()
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        // Password textfield set up
        password.backgroundColor = UIColor.clearColor()
        password.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
     
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Changes the status bar to white
        return UIStatusBarStyle.LightContent
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
        
        // Resigns the keyboards when it senses a touch
        emailText.resignFirstResponder()
        password.resignFirstResponder()
        
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
        // Logs the user out
        try! FIRAuth.auth()!.signOut()
    }
    
    func finishLogin(authData: FIRUser?, error: NSError?, type: Provider) {
        
        if error == nil {
            // Save the user id locally
            NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: "uid")
            if let user = authData {
                // If the user didnt sign up with thier email then this will be nil when first signing up with facebook or google and we should check and make sure the user is created in our database where we will then store the email address with the account auth
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
                            return UIImageJPEGRepresentation(UIImage(named: "default_pic.png")!, 0.5)!
                        }
                        
                        // This is a temp fix for the facebook email problem
                        if email == nil {
                            SwiftOverlays.removeAllBlockingOverlays()
                            FBSDKLoginManager().logOut()
                            user.deleteWithCompletion({ (error) in
                                if let error = error {
                                    showAppleAlertViewWithText(error.description, presentingVC: self)
                                }
                            })
                            SCLAlertView().showError("Error", subTitle: "Sorry we are having trouble connecting to your facebook account, please sign up using a different method.")
                            return
                        }
                    
                        user.updateEmail(email! , completion: { (error) in
                            if let error = error {
                                GIDSignIn.sharedInstance().signOut()
                                FBSDKLoginManager().logOut()
                                SwiftOverlays.removeAllBlockingOverlays()
                                if error.code == 17007 {
                                    SCLAlertView().showError("Error", subTitle: "The email address is already in use by another account.")
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
                                                    let userInfo = ["name": name, "username": username, "email":email, "privacy":false, "provider":type.rawValue]
                                                    currentUser.setValue(userInfo)
                                                    addedUserToBatch()
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
                    addedUserToBatch()
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                }
            }
        } else {
            SwiftOverlays.removeAllBlockingOverlays()
            if error?.code == 17011 || error?.code == 17009 {
                let alert = SCLAlertView(appearance: K.Apperances.NormalApperance)
                alert.showNotice("Error", subTitle: "Invalid Credentails")
            } else {
                showAppleAlertViewWithText(error!.description, presentingVC: self)
            }
        }
    }
    
    // MARK: - Google login delegates
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
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
                withError error: NSError!) {
        // Logs the user out
        try! FIRAuth.auth()!.signOut()
    }
    
    // Mark: - Helper login methods
    func promptForUserName(handler: (username:String?) -> ()) {
        
        let promptAlert = SCLAlertView(appearance: K.Apperances.UserNamePromptApperance)
        usernameTextField = promptAlert.addTextField("username")
        usernameTextField.delegate = self
        usernameTextField.autocapitalizationType = .None
        
        promptAlert.addButton("Apply") {
            checkIfValidUsername(self.usernameTextField.text!, vc: self, handler: { (isValid) in
                if isValid {
                    handler(username: self.usernameTextField.text!)
                } else {
                    let error = SCLAlertView(appearance: K.Apperances.UserNamePromptApperance)
                    error.addButton("Ok", action: {
                        self.promptForUserName({ (username) in
                            handler(username: username)
                        })
                    })
                    error.showNotice("Error", subTitle: "Username isn't right length, contains whitespace, contains invaild characters, or is already in use")
                }
            })
        }
        promptAlert.addButton("Cancel") {
            handler(username: nil)
        }
        SwiftOverlays.removeAllBlockingOverlays()
        promptAlert.showNotice("Enter a moon username", subTitle: "Must be 5-12 chars long and contain no whitespaces/special characters")
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(usernameTextField) {
            usernameTextField.text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string.lowercaseString)
            return false
        }
        return true
    }
    
}
