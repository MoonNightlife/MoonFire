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
 
 enum AccountActions: Int {
    case ChangePassword
    case Logout
    case DeleteAccount
 }
 
 enum AccountFields: Int {
    case Username
    case Name
    case Birthday
    case Sex
    case Email
    case Bio
    case FavoriteDrink
    case City
    case Privacy
    case PhoneNumber
    case PushNotifications
 }
 
 enum SettingSections: Int {
    case MyAccount
    case Actions
 }

class UserSettingsViewController: UITableViewController, UITextFieldDelegate, SegueHandlerType  {
    
    enum SegueIdentifier: String {
        case EnterPhoneNumber
        case PushNotifications
    }
    
    var handles = [UInt]()
    
    let userService: UserBackendService = FirebaseUserService()
    let userAccountService: UserAccountBackendService = FirebaseUserAccountService()
    let validationService: AccountValidation = ValidationService()
    let cityService: CityService = FirebaseCityService()
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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .EnterPhoneNumber:
            let vc = segue.destinationViewController as? PhoneNumberEntryViewController
            vc?.partOfSignUpFlow = false
        case .PushNotifications:
            break
        }
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
            .flatMapLatest({ (result) -> Observable<BackendResult<City2>> in
                switch result {
                case .Success(let user):
                    self.assignValuesToLabels(user)
                    // If the user has a simulated location retrieve it
                    if let cityID = user.userProfile?.simLocation {
                        return self.cityService.getCityFor(cityID)
                    } else {
                        // Create a city with the name "Location Based" to be displayed
                        let locationBasedCity = City2(name: "Location Based")
                        return Observable.just(BackendResult.Success(response: locationBasedCity))
                    }
                case .Failure(let error):
                    return Observable.just(BackendResult.Failure(error: error))
                }
            })
            .subscribeNext { (result) in
                switch result {
                case .Success(let city):
                    self.city.detailTextLabel?.text = city.name
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
            if let email = newInfo.text {
                let emailValidation = self.validationService.isValid(Email: email)
                if emailValidation.isValid {
                    self.userAccountService.updateEmail(email)
                        .subscribeNext({ (response) in
                            switch response {
                            case .Success:
                                    print("saved")
                            case .Failure(let error):
                                    print(error)
                            }
                        })
                        .addDisposableTo(self.disposeBag)
                } else {
                    SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Error", subTitle: emailValidation.Message)
                }
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
            if let favDrink = newInfo.text {
                self.userService.updateFavoriteDrink(favDrink)
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
        })
        
        alertView.showNotice("Update Drink", subTitle: "Your favorite drink will display on your profile, and help us find specials for you")
    }
    private func promptForCity() {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        
        alertView.addButton("Location Based", action: {
            // Once the location simLocation is removed the rest of the app will use the gps location when it finds nil as the sim
            // TODO: Move location services to a service struct
            checkAuthStatus(self)
            self.userService.updateCity(nil)
                .subscribeNext({ (response) in
                    switch response {
                    case .Success:
                        print("saved")
                    case .Failure(let error):
                        print(error)
                    }
                })
                .addDisposableTo(self.self.disposeBag)
        })
        
        cityService.getCities()
            .subscribeNext { (chosenCity) in
                switch chosenCity {
                case .Success(let response):
                    for city in response {
                        alertView.addButton(city.name, action: {
                            // TODO: this is a code smell and needs to be changed. One should not subscribe to an observable inside another subscription
                            self.userService.updateCity(city)
                                .subscribeNext({ (response) in
                                    switch response {
                                    case .Success:
                                        print("saved")
                                    case .Failure(let error):
                                        print(error)
                                    }
                                })
                                .addDisposableTo(self.self.disposeBag)
                        })
                    }
                    
                    alertView.showNotice("Change City", subTitle: "Pick a city below")
                    
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
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
    private func promptForBio() {
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        let newInfo =  alertView.addTextField("New Bio")
        newInfo.tag = 1
        newInfo.delegate = self
        newInfo.autocapitalizationType = .None
        alertView.addButton("Save", action: {
            if let bio = newInfo.text {
                self.userService.updateBio(bio)
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
        })
        alertView.showNotice("Update Bio", subTitle: "People can see your bio when viewing your profile")
    }
    
    //MARK: - Methods for users to perform actions on their profile
    private func changePassword() {
        self.promptReauthAccount { (success) in
            if success {
                self.promptForPasswordChange()
            }
        }
    }
    private func promptReauthAccount(handler: (success: Bool) -> ()) {
        
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        let email = alertView.addTextField("Email")
        email.autocapitalizationType = .None
        let password = alertView.addTextField("Password")
        password.autocapitalizationType = .None
        password.secureTextEntry = true
        
        // TODO: Add validation check for the email, and also add a way to see the help message returned from the service
        alertView.addButton("Continue") {
            if let email = email.text, let password = password.text {
                let credentials = ProviderCredentials.Email(credentials: EmailCredentials(email: email, password: password))
                self.userAccountService.reauthenticateAccount(credentials)
                    .subscribeNext({ (response) in
                        switch response {
                        case .Success:
                            handler(success: true)
                        case .Failure(let error):
                            // Call the function to reauth again if there was an error
                            // TODO: Present a message to the user so they what went wrong during the log in
                            self.promptReauthAccount({ (success) in
                                handler(success: success)
                            })
                            print(error)
                        }
                    })
                    .addDisposableTo(self.disposeBag)
            }
        }
        
        // Display the edit alert
        alertView.showNotice("Sign In", subTitle: "You must sign in again before changing your password.")
    }
    private func promptForPasswordChange() {
        // TODO: Add a way for the user to see the suggested hints from the validation service
        // Setup alert view so user can enter information for password change
        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
        let newPassword = alertView.addTextField("New password")
        newPassword.autocapitalizationType = .None
        newPassword.secureTextEntry = true
        let retypedPassword = alertView.addTextField("Retype password")
        retypedPassword.autocapitalizationType = .None
        retypedPassword.secureTextEntry = true
        
        // This checks and makes sure the passwords entered into the fields are acceptable to be used to update the user's password
        let password = newPassword.rx_text
        let reypedPWord = retypedPassword.rx_text
        let validPassword = Observable.combineLatest(password, reypedPWord, resultSelector: {
            return self.validationService.isValid(Password: $0).isValid && ($0 == $1)
        })
        
        // Once the user selects the update firebase attempts to change password on server
        let updateButton = alertView.addButton("Update") {
            
            if let passsword = newPassword.text {
                    self.userAccountService.changePasswordForSignedInUser(passsword)
                        .subscribeNext({ (response) in
                            switch response {
                            case .Success:
                                print("Password Changed")
                            case .Failure(let error):
                                print(error)
                            }
                        })
                        .addDisposableTo(self.disposeBag)
            }
            
        }
        
        // Disable update field if the passwords aren't valid 
        validPassword
            .subscribeNext { (isValid) in
                updateButton.enabled = isValid
                if isValid {
                    updateButton.alpha = 1
                } else {
                    updateButton.alpha = 0.5
                }
            }
            .addDisposableTo(disposeBag)
        
        // Display the edit alert
        alertView.showNotice("Change Password", subTitle: "")
        
    }
    private func logout() {
        //        GIDSignIn.sharedInstance().signOut()
        //        FBSDKLoginManager().logOut()
        
        userAccountService.logSignedInUserOut()
            .subscribeNext { (response) in
                switch response {
                case .Success:
                    NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
                    let loginVC: LoginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
                    self.presentViewController(loginVC, animated: true, completion: nil)
                case .Failure(let error):
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
    }
    private func deleteAccount() {
        
    }
    
    //MARK: - Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let section = SettingSections(rawValue: indexPath.section) {
            switch section {
            case .MyAccount:
                // Show popup for editing
                if let field = AccountFields.init(rawValue: indexPath.row) {
                    switch field {
                    case .Name:
                        promptForName()
                    case .Birthday:
                        promptForBirthday()
                    case .Sex:
                        promptForSex()
                    case .Email:
                        promptForEmail()
                    case .Bio:
                        promptForBio()
                    case .FavoriteDrink:
                        promptForFavoriteDrink()
                    case .City:
                        promptForCity()
                    case .PhoneNumber:
                        // TODO: show phone number view controller once this cell is tapped
                        break
                    default: break
                    }
                }
            case .Actions:
                if let action = AccountActions.init(rawValue: indexPath.row) {
                    switch action {
                    case .ChangePassword:
                        changePassword()
                    case .Logout:
                        logout()
                    case .DeleteAccount:
                        deleteAccount()
                    }
                }
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
   }
}

