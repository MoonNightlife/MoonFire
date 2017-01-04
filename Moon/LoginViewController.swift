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
import RxCocoa
import RxSwift

struct LoginInputs {
    let email: ControlProperty<String>
    let password: ControlProperty<String>
    let loginButtonTapped: ControlEvent<Void>
    let facebookLoginButtonTapped: ControlEvent<Void>
    let googleLoginButttonTapped: ControlEvent<Void>
    let forgotPasswordButtonTapped: ControlEvent<Void>
}

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate, ErrorPopoverRenderer, SegueHandlerType, OverlayRenderer {
    
    enum SegueIdentifier: String {
        case LoggedIn
        case EnterProfileInformation
    }
    
    //MARK: - Properties
    var imageView: UIImageView?
    let scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
    var moveToLocation:CGFloat = 0
    var finishedScroll = false
    var stop = false
    var inMiddleOfLogin = false
    var usernameTextField: UITextField!
    
    private var viewModel: LoginViewModel!
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Outlets
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    @IBOutlet weak var googleLoginButton: UIButton!
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
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        viewSetup()
        createAndBindViewModel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // MARK: - Helper functions for view
    func viewSetup(){
        
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
        
//        if error == nil {
//            // Save the user id locally
//            NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: "uid")
//            if let user = authData {
//                        for profile in user.providerData {
//                            let name = profile.displayName
//                            let email = profile.email
//                            let photoURL = profile.photoURL
//                            var photo: NSData {
//                                if let url = photoURL {
//                                    if let p = NSData(contentsOfURL: url) {
//                                        return p
//                                    }
//                                }
//                                return UIImageJPEGRepresentation(UIImage(named: "default_pic.png")!, 0.5)!
//                            }
//                            
//                            // This is a temp fix for the facebook email problem
//                            if email == nil {
//                                SwiftOverlays.removeAllBlockingOverlays()
//                                FBSDKLoginManager().logOut()
//                                user.deleteWithCompletion({ (error) in
//                                    if let error = error {
//                                        showAppleAlertViewWithText(error.description, presentingVC: self)
//                                    }
//                                })
//                                SCLAlertView().showError("Error", subTitle: "Sorry we are having trouble connecting to your account, please sign up using a different method.")
//                                return
//                            }
//                            
//                            user.updateEmail(email! , completion: { (error) in
//                                if let error = error {
//                                    GIDSignIn.sharedInstance().signOut()
//                                    FBSDKLoginManager().logOut()
//                                    SwiftOverlays.removeAllBlockingOverlays()
//                                    if error.code == 17007 {
//                                        SCLAlertView().showError("Error", subTitle: "The email address is already in use by another account.")
//                                    } else {
//                                        showAppleAlertViewWithText(error.description, presentingVC: self)
//                                    }
//                                    user.deleteWithCompletion({ (error) in
//                                        if let error = error {
//                                            showAppleAlertViewWithText(error.description, presentingVC: self)
//                                        }
//                                    })
//                                } else {
//                                    checkIfUserIsInFirebase(email!, vc: self, handler: { (isUser) in
//                                        self.promptForUserName({ (username) in
//                                            SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
//                                            if let username = username, let name = name, let email = email {
//                                                storageRef.child("profilePictures").child((FIRAuth.auth()?.currentUser?.uid)!).child("userPic").putData(photo, metadata: nil) { (metaData, error) in
//                                                    if let error = error {
//                                                        SwiftOverlays.removeAllBlockingOverlays()
//                                                        showAppleAlertViewWithText(error.description, presentingVC: self)
//                                                    } else {
//                                                        let userInfo = ["name": name, "username": username, "email":email, "privacy":false, "provider":type.rawValue]
//                                                        currentUser.setValue(userInfo)

//                                                        SwiftOverlays.removeAllBlockingOverlays()
//                                                        promptForPhoneNumberWithCompletionHandler(self, handler: { (done) in
//                                                            if done {
//                                                                self.performSegueWithIdentifier("LoggedIn", sender: nil)
//                                                            }
//                                                        })
//                                                    }
//                                                }
//                                            } else {
//                                                GIDSignIn.sharedInstance().signOut()
//                                                FBSDKLoginManager().logOut()
//                                                user.deleteWithCompletion({ (error) in
//                                                    if let error = error {
//                                                        showAppleAlertViewWithText(error.description, presentingVC: self)
//                                                    }
//                                                })
//                                            }
//                                        })
//                                    })
//                                }
//                    } else {
//                        self.performSelector(#selector(LogInViewController.performLoginSegue), withObject: nil, afterDelay: 1)
//                    }
//
//            }
//        }
    }
    
    func performLoginSegue() {
        SwiftOverlays.removeAllBlockingOverlays()
        performSegueWithIdentifier("LoggedIn", sender: nil)
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
    


    
    func createAndBindViewModel() {
        let inputs = LoginInputs(email: emailText.rx_text, password: password.rx_text, loginButtonTapped: loginButton.rx_tap, facebookLoginButtonTapped: fbLoginButton.rx_tap, googleLoginButttonTapped: googleLoginButton.rx_tap, forgotPasswordButtonTapped: forgotPasswordButton.rx_tap)
        
        viewModel = LoginViewModel(inputs: inputs, userService: FirebaseUserService(), facebookService: FacebookService(), pushNotificationService: BatchService())
        
        viewModel.errorMessageToDisplay.asObservable()
            .subscribeNext { (errorMessage) in
                guard let message = errorMessage else {
                    return
                }
                self.presentError(ErrorOptions(errorMessage: message))
            }
            .addDisposableTo(disposeBag)
        
        viewModel.shouldShowOverlay.asObservable()
            .subscribeNext { (action) in
                switch action {
                case .Remove:
                    self.removeOverlay()
                case .Show(let options):
                    self.presentOverlayWith(Options: options)
                }
            }
            .addDisposableTo(disposeBag)
        
        viewModel.loginComplete.asObservable()
            .subscribeNext { (complete) in
                if complete {
                    self.performSegueWithIdentifier(SegueIdentifier.LoggedIn, sender: self)
                }
            }
            .addDisposableTo(disposeBag)
        
        viewModel.moreUserInfomationNeeded.asObservable()
            .subscribeNext { (showDisplayInformationController) in
                if showDisplayInformationController {
                    self.performSegueWithIdentifier(.EnterProfileInformation, sender: self)
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
}
