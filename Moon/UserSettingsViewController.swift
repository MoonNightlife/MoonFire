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
import SwiftOverlays
import FBSDKLoginKit
import GoogleSignIn
import RxCocoa
import RxSwift
import ObjectMapper

class UserSettingsViewController: UITableViewController, UITextFieldDelegate  {
    
    var handles = [UInt]()
    
    var userService: UserBackendService = FirebaseUserService()
    var validationService: AccountValidation = ValidationService()
    private let disposeBag = DisposeBag()

    // MARK: - Outlets
    @IBOutlet weak var userName: UITableViewCell!
    @IBOutlet weak var name: UITableViewCell!
    @IBOutlet weak var email: UITableViewCell!
    @IBOutlet weak var birthday: UITableViewCell!
    @IBOutlet weak var sex: UITableViewCell!
    @IBOutlet weak var bio: UITableViewCell!
    @IBOutlet weak var favoriteDrinks: UITableViewCell!
    @IBOutlet weak var phoneNumber: UITableViewCell!
    @IBOutlet weak var city: UITableViewCell!
    @IBOutlet weak var privacy: UITableViewCell!
    @IBOutlet weak var privacySwitch: UISwitch!
    
    // MARK: - Action
    @IBAction func privacyChanged(sender: UISwitch) {
        userService.updatePrivacy(sender.on).subscribeNext { (response) in
            switch response {
            case .Success:
                print("saved")
            case .Failure(let error):
                print(error)
            }
        }
        .addDisposableTo(disposeBag)
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func logout() {
        
        SwiftOverlays.showBlockingWaitOverlayWithText("Logging Out")
        if FIRAuth.auth()?.currentUser?.providerData != nil {
            GIDSignIn.sharedInstance().signOut()
            FBSDKLoginManager().logOut()
        }
        // Logs the user out and removes uid from local data store
        do {
            try FIRAuth.auth()!.signOut()
            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
            let loginVC: LoginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
            SwiftOverlays.removeAllBlockingOverlays()
            self.presentViewController(loginVC, animated: true, completion: nil)
        } catch {
            showAppleAlertViewWithText("Try again", presentingVC: self)
        }
        
    }
    
    @IBAction func deleteUserAccount(sender: AnyObject) {
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        checkProviderForCurrentUser(self) { (type) in
            if type == .Facebook || type == .Google {
                alertView.addButton("Delete") {
                    SwiftOverlays.showBlockingWaitOverlayWithText("Deleting Account")
                        self.reAuthForFacebookOrGoogle(type, handler: { (error) in
                            if let error = error {
                                SwiftOverlays.removeAllBlockingOverlays()
                                print(error)
                            } else {
                                self.finishDeletingAccount({ (didFinish) in
                                    if didFinish {
                                        self.unAuthForFacebookOrGoogle(type, handler: { (error) in
                                            if let error = error {
                                                print(error)
                                            } else {
                                                SwiftOverlays.removeAllBlockingOverlays()
                                                let loginVC: LoginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
                                                self.presentViewController(loginVC, animated: true, completion: nil)
                                            }
                                        })
                                    }
                                })
                            }
                        })
                   }
                alertView.showNotice("Delete Account", subTitle: "Are you sure you want to delete your account?")
            } else {
                let email = alertView.addTextField("Email")
                email.autocapitalizationType = .None
                let password = alertView.addTextField("Password")
                password.secureTextEntry = true
                alertView.addButton("Delete") {
                    SwiftOverlays.showBlockingWaitOverlayWithText("Deleting Account")
                    self.seeIfUserIsDeleteingCurrentlyLoginAccount(email.text!, handler: { (isTrue) in
                        if isTrue {
                            self.reAuthUserWithCredentials(email.text!, password: password.text!, handler: { (error) in
                                if let error = error {
                                    SwiftOverlays.removeAllBlockingOverlays()
                                    print(error)
                                } else {
                                    self.finishDeletingAccount({ (didFinish) in
                                        if didFinish {
                                            self.unAuthCurrentUser({ (error) in
                                                if let error = error {
                                                    print(error)
                                                } else {
                                                    SwiftOverlays.removeAllBlockingOverlays()
                                                    let loginVC: LoginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
                                                    self.presentViewController(loginVC, animated: true, completion: nil)
                                                }
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    })
                }
                alertView.showNotice("Delete Account", subTitle: "Please enter your username and password to delete your account.")
            }
        }
    }
    
    @IBAction func changePassword() {
        // Reset the password once the user clicks button in tableview
        // Setup alert view so user can enter information for password change
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        let newPassword = alertView.addTextField("New password")
        newPassword.autocapitalizationType = .None
        newPassword.secureTextEntry = true
        let retypedPassword = alertView.addTextField("Retype password")
        retypedPassword.autocapitalizationType = .None
        retypedPassword.secureTextEntry = true
        
        // Once the user selects the update firebase attempts to change password on server
        alertView.addButton("Update") {
            let user = FIRAuth.auth()?.currentUser
            if user != nil && newPassword.text == retypedPassword.text && newPassword.text?.characters.count > 4{
                self.showWaitOverlayWithText("Changing password")
                FIRAuth.auth()?.currentUser?.updatePassword(newPassword.text!, completion: { (error) in
                    self.removeAllOverlays()
                    if let error = error {
                        showAppleAlertViewWithText(error.description, presentingVC: self)
                    }
                })
            } else {
                SCLAlertView().showError("Can't reset password", subTitle: "Make sure both passwords are the same, and that it is at least 5 characters in length")
            }
        }
        // Display the edit alert
        alertView.showNotice("Change Password", subTitle: "")
    }
    
    // MARK: - Helper functions for deleting an account
    func finishDeletingAccount(handler: (didFinish: Bool)->()) {
        self.removeFriendRequestForUserID(currentUser.key)
        self.getUserNameForCurrentUser({ (username) in
            if username != nil {
                self.removeFriendRequestSentOutByUserName(username!, handler: { (didDelete) in
                    if didDelete {
                        self.removeBarActivityAndDecrementBarCountForCurrentUser({ (didDelete) in
                            if didDelete {
                                self.removeCurrentUserFromFriendsListAndBarFeedOfOtherUsers(username!, handler: { (didDelete) in
                                    if didDelete {
                                        // Remove user information from database
                                        rootRef.child("phoneNumbers").child(currentUser.key).removeValue()
                                        rootRef.child("users").child(currentUser.key).removeAllObservers()
                                        rootRef.child("users").child(currentUser.key).removeValue()
                                        handler(didFinish: true)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })
    }
    
    func seeIfUserIsDeleteingCurrentlyLoginAccount(email: String, handler: (isTrue: Bool)->()) {
        // Check and make sure user is deleteing the account he is signed into
        if FIRAuth.auth()?.currentUser?.email == email.lowercaseString {
            handler(isTrue: true)
        } else {
            SwiftOverlays.removeAllBlockingOverlays()
            SCLAlertView().showError("Could Not Delete", subTitle: "Verify you are signed into the account you are trying to delete")
            handler(isTrue: false)
        }
    }
    
    func removeFriendRequestForUserID(ID:String) {
        // Remove any friend request for that user
        rootRef.child("friendRequest").child(ID).removeValue()
    }
    
    func reAuthForFacebookOrGoogle(type: Provider, handler: (error: NSError?) -> ()) {
        var credentials: FIRAuthCredential!
        if type == Provider.Google {
            let authentication = GIDSignIn.sharedInstance().currentUser.authentication
            credentials = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                      accessToken: authentication.accessToken)
        } else if type == Provider.Facebook {
            credentials = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        }
        
        FIRAuth.auth()?.currentUser?.reauthenticateWithCredential(credentials, completion: { (error) in
            if let error = error {
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                handler(error: nil)
            }
        })
    }
    
    func unAuthForFacebookOrGoogle(type: Provider, handler: (error: NSError?) -> ()) {
        self.deleteProfilePictureForUser(currentUser.key, handler: { (didDelete) in
            if didDelete {
                FIRAuth.auth()?.currentUser?.deleteWithCompletion({ (error) in
                    if let error = error {
                        SwiftOverlays.removeAllBlockingOverlays()
                        SCLAlertView().showError("Error", subTitle: "Could not delete, please email support@moonnightlifeapp.com")
                        handler(error: error)
                    } else {
                        if type == .Google {
                            GIDSignIn.sharedInstance().signOut()
                        } else if type == .Facebook {
                            FBSDKLoginManager().logOut()
                        }
                        handler(error: nil)
                    }
                })
            }
        })
    }
    
    func reAuthUserWithCredentials(email: String, password: String, handler: (error: NSError?) -> ()) {
        // Sign the user in again before deleting account because the method "deleteWithCompletion" requires it
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            if let error = error {
                SwiftOverlays.removeAllBlockingOverlays()
                handler(error: error)
                print(error)
            } else {
                handler(error: nil)
            }
        })
    }
    
    func unAuthCurrentUser(handler: (error: NSError?) -> ()) {
        self.deleteProfilePictureForUser(currentUser.key, handler: { (didDelete) in
            if didDelete {
                FIRAuth.auth()?.currentUser?.deleteWithCompletion({ (error) in
                    if let error = error {
                        SwiftOverlays.removeAllBlockingOverlays()
                        SCLAlertView().showError("Error", subTitle: "Could not delete, please email support@moonnightlifeapp.com")
                        handler(error: error)
                    } else {
                        handler(error: nil)
                    }
                })
            }
        })
    }
    
    func getUserNameForCurrentUser(handler: (username: String?) -> ()) {
        // Get username for current user
        currentUser.child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if let username = snap.value {
                handler(username: username as? String)
            } else {
                SwiftOverlays.removeAllBlockingOverlays()
                handler(username: nil)
            }
            }) { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(username: nil)
        }
    }
    
    func removeBarActivityAndDecrementBarCountForCurrentUser(handler: (didDelete: Bool) -> ()) {
        // Decrement user if they are going to a bar
        currentUser.child("currentBar").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull),let currentBar = snap.value {
                decreamentUsersGoing(rootRef.child("bars").child(currentBar as! String))
                // Remove bar activity
                rootRef.child("barActivities").child(currentUser.key).removeValue()
            }
            handler(didDelete: true)
            }) { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func removeCurrentUserFromFriendsListAndBarFeedOfOtherUsers(username: String, handler: (didDelete: Bool) -> ()) {
        // Grabs all the friends the current user has and deletes the current users presence from other users friends list and bar feed
        currentUser.child("friends").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for user in snap.children {
                if !(user is NSNull) {
                    let user = user as! FIRDataSnapshot
                    rootRef.child("users").child(user.value as! String).child("friends").child(username).removeValue()
                    rootRef.child("users").child(user.value as! String).child("barFeed").child(currentUser.key).removeValue()
                }
            }
            handler(didDelete: true)
            }) { (error) in
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func removeFriendRequestSentOutByUserName(username: String, handler: (didDelete: Bool) -> ()) {
        rootRef.child("friendRequest").queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { (snap) in
            for userHolder in snap.children {
                let userHolder = userHolder as! FIRDataSnapshot
                for user in userHolder.children {
                    let user = user as! FIRDataSnapshot
                    if username == user.key {
                        user.ref.removeValue()
                    }
                }
            }
            handler(didDelete: true)
            }) { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
                handler(didDelete: false)
        }
    }
    
    func deleteProfilePictureForUser(Id: String, handler:(didDelete: Bool) -> ()) {
        // Delete the file
        storageRef.child("profilePictures").child(currentUser.key).child("userPic").deleteWithCompletion { (error) -> Void in
            if let error = error {
                handler(didDelete: false)
                showAppleAlertViewWithText(error.description, presentingVC: self)
            } else {
                handler(didDelete: true)
            }
        }
    }
    
    // MARK: - View controller lifecycle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "Settings"
        
        // Grabs all the user settings and reloads the table view
        getUserSettings()
        setUpNavigation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for handle in handles {
            rootRef.removeObserverWithHandle(handle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UINavigationBar.appearance().tintColor = UIColor.darkGrayColor()
    }
    
    // MARK: - Helper function for view
    func setUpNavigation() {
        
        // Navigation controller set up
        self.navigationItem.title = "Account Settings"
        self.navigationItem.backBarButtonItem?.title = ""
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        // Top View set up
        let header = "Header_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
    }

    private func getUserSettings() {
        
        userService.getSignedInUserInformation()
            .subscribeNext { (result) in
                switch result {
                case .Success(let user):
                    self.assignValuesToLabels(user)
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    private func assignValuesToLabels(user: User2) {
        self.userName.detailTextLabel?.text = user.userSnapshot?.username

        self.name.detailTextLabel?.text = (user.userSnapshot?.firstName ?? "") + " " + (user.userSnapshot?.lastName ?? "")
        //TODO: get email from provider
        //self.email.detailTextLabel?.text = user.email
        self.birthday.detailTextLabel?.text = user.userProfile?.birthday
        if user.userProfile?.sex == .None {
            self.sex.detailTextLabel?.text = ""
        } else {
            self.sex.detailTextLabel?.text = user.userProfile?.sex?.stringValue
        }
        
        self.bio.detailTextLabel?.text = user.userProfile?.bio
        self.favoriteDrinks.detailTextLabel?.text = user.userProfile?.favoriteDrink
        //TODO: format phone number for gui
        self.phoneNumber.detailTextLabel?.text = user.userProfile?.phoneNumber
        self.privacySwitch.on = user.userSnapshot?.privacy ?? false
        
        if let simLocation = user.userProfile?.simLocation {
            self.city.detailTextLabel?.text = simLocation.name
        } else {
            self.city.detailTextLabel?.text = "Location Based"
        }
        
        self.tableView.reloadData()

    }
    
    //MARK: - Text Field Delegate Methods
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if textField.tag == 1 {
            let maxLength = K.Profile.MaxCharForBio
            let currentString: NSString = textField.text!
            let newString: NSString =
                currentString.stringByReplacingCharactersInRange(range, withString: string)
            return newString.length <= maxLength
        }
        
        if textField.tag == 2 {
            let maxLength = K.Profile.MaxCharForFavoriteDrink
            let currentString: NSString = textField.text!
            let newString: NSString =
                currentString.stringByReplacingCharactersInRange(range, withString: string)
            return newString.length <= maxLength
        }
        
        // Used to format the phone number entered into the first prompted text box
        if textField.tag == 69 {
            return shouldPhoneNumberTextChangeHelperMethod(textField, range: range, string: string)
        }
        
        // Used to prevent the user from entering in more than four characters
        if textField.tag == 169 {
            return shouldPinNumberTextFieldChange(textField, range: range, string: string)
        }
        
        return true
    }

    //MARK: - Methods to prompt user to edit thier profile information
    private func promptForName() {
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        
        let firstNameTextField = alertView.addTextField("First Name")
        let lastNameTextField = alertView.addTextField("Last Name")
        
        alertView.addButton("Save", action: {
            if let fName = firstNameTextField.text, let lName = lastNameTextField.text {
                
                let firstNameValidation = self.validationService.isValid(Name: fName)
                let lastNameValidation = self.validationService.isValid(Name: lName)
                
                if firstNameValidation.isValid && lastNameValidation.isValid {
                    self.userService.updateName(fName, lastName: lName)
                        .subscribeNext({ (response) in
                            switch response {
                            case .Success:
                                print("saved")
                            case .Failure(let error):
                                print(error)
                            }
                        })
                        .addDisposableTo(self.disposeBag)
                }
                
            }
        })
        
        alertView.showNotice("Update Name", subTitle: "Your name is how other users see you.")
    }
    private func promptForEmail() {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        
        let newInfo = alertView.addTextField("New email")
        newInfo.autocapitalizationType = .None
        alertView.addButton("Save") {
            self.showWaitOverlayWithText("Changing email")
            // Updates the email account for user auth
            if isValidEmail(newInfo.text!) {
                FIRAuth.auth()?.currentUser?.updateEmail(newInfo.text!, completion: { (error) in
                    self.removeAllOverlays()
                    if error == nil {
                        currentUser.updateChildValues(["email": newInfo.text!])
                    } else {
                        print(error)
                    }
                })
            } else {
                SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Error", subTitle: "Make sure text is valid email")
            }
        }
        alertView.showNotice("Update Email", subTitle: "Changes your sign in email")
    }
    private func promptForFavoriteDrink() {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        
        let newInfo = alertView.addTextField("New Drink")
        newInfo.delegate = self
        newInfo.tag = 2
        newInfo.autocapitalizationType = .None
        alertView.addButton("Save", action: {
            currentUser.updateChildValues(["favoriteDrink": newInfo.text!])
        })
        
        alertView.showNotice("Update Drink", subTitle: "Your favorite drink will display on your profile, and help us find specials for you")
    }
    private func promptForCity() {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        
        var cityChoices = [City]()
        SwiftOverlays.showBlockingWaitOverlayWithText("Grabbing Cities")
        rootRef.child("cities").observeSingleEventOfType(.Value, withBlock: { (snap) in
            for city in snap.children {
                // Using the city stuct for convience, so the image is going to be set to nil
                let city = City(image: nil, name: ((city as! FIRDataSnapshot).value as! NSDictionary)["name"] as? String, long: ((city as! FIRDataSnapshot).value as! NSDictionary)["long"] as? Double, lat: ((city as! FIRDataSnapshot).value as! NSDictionary)["lat"] as? Double, id: nil)
                
                cityChoices.append(city)
                
                alertView.addButton(city.name!, action: {
                    currentUser.child("simLocation").child("long").setValue(city.long)
                    currentUser.child("simLocation").child("lat").setValue(city.lat)
                    currentUser.child("simLocation").child("name").setValue(city.name)
                })
            }
            alertView.addButton("Location Based", action: {
                // Once the location simLocation is removed the rest of the app will use the gps location when it finds nil as the sim
                checkAuthStatus(self)
                currentUser.child("simLocation").removeValue()
            })
            SwiftOverlays.removeAllBlockingOverlays()
            alertView.showNotice("Change City", subTitle: "Pick a city below")
            }, withCancelBlock: { (error) in
                SwiftOverlays.removeAllBlockingOverlays()
                showAppleAlertViewWithText(error.description, presentingVC: self)
        })

    }
    private func promptForSex() {
        
        let pickerData = [
            ["value": "Male", "display": "Male"],
            ["value": "Female", "display": "Female"],
            ["value": "None", "display": "Rather Not Say"]
        ]
        
        let currentSex = sex.detailTextLabel?.text
        
        PickerDialog().show("Select sex", doneButtonTitle: "Apply", cancelButtonTitle: "Cancel", options: pickerData, selected: currentSex, callback: { (sex) in
                self.userService.updateSex(sex)
                    .subscribeNext({ (response) in
                        switch response {
                        case .Success:
                            print("saved")
                        case .Failure(let error):
                            print(error)
                        }
                    })
                    .addDisposableTo(self.disposeBag)
        })

    }
    private func promptForBirthday() {
        
        // Used to set the default date for the date picker
        let currentBirthday = birthday.detailTextLabel?.text?.convertMediumStyleStringToDate()
        
        DatePickerDialog().show("Update Birthday", doneButtonTitle: "Save", cancelButtonTitle: "Cancel", defaultDate: currentBirthday ?? NSDate(), datePickerMode: .Date, callback: { (date) in
            self.userService.updateBirthday(date.convertDateToMediumStyleString())
                .subscribeNext({ (response) in
                    switch response {
                    case .Success:
                        print("saved")
                    case .Failure(let error):
                        print(error)
                    }
                })
                .addDisposableTo(self.disposeBag)
        })
    }
    
    //MARK: - Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Show popup for editing
        if indexPath.section == 0 {
            switch indexPath.row {
            case 1:
                promptForName()
            case 2:
                promptForBirthday()
            case 3:
                promptForSex()
            case 4:
                promptForEmail()
            case 5:
                updateBio(self)
            case 6:
                promptForFavoriteDrink()
            case 7:
                promptForCity()
            case 9:
                promptForPhoneNumber(self)
            default: break
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
   }
}

