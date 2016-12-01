//
//  CreateAccountViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import SwiftOverlays
import Firebase
import SCLAlertView
import RxCocoa
import RxSwift

class CreateAccountViewController: UIViewController, UITextFieldDelegate, SegueHandlerType, ValidationTextFieldDelegate {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case NewLogin
    }
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailText: ValidationTextField!
    @IBOutlet weak var passwordText: ValidationTextField!
    @IBOutlet weak var username: ValidationTextField!
    @IBOutlet weak var retypePassword: ValidationTextField!
    @IBOutlet weak var name: ValidationTextField!
    @IBOutlet weak var maleOrFemale: UISegmentedControl!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    var datePickerView: UIDatePicker!
    
    var phoneNumberVerified = false
    var phoneNumberToSave: String?
    
    

    var viewModel: CreateAccountViewModel!
    let dispoeBag = DisposeBag()
    
    
    // MARK: - Actions
    @IBAction func ageEditingStarted(sender: UITextField) {
        sender.inputView = datePickerView
    }
    
    // Called when the user exits the text field
    @IBAction func phoneNumberFieldEntered(sender: UITextField) {
        if let phonenumber = phoneNumber.text {
            if phonenumber.characters.count == 17 {
                verifyPhoneNumber(self, phoneNumber: phonenumber, handler: { (didVerify) in
                    if didVerify {
                        self.phoneNumberVerified = true
                        print(phonenumber)
                        self.phoneNumberToSave = phonenumber
                    }
                })
            } else {
                SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Invalid Phone Number", subTitle: "Please correct and try again")
            }
        }
    }
    
    
    
 
    
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func createAccount(sender: UIButton) {
        //TODO: Move validation to the user model
        // Populate vars with user data from label
        SwiftOverlays.showBlockingWaitOverlayWithText("Creating User")
        let userName = self.username.text!
        let email = emailText.text!.lowercaseString
        let password = passwordText.text!
        let retypePassword = self.retypePassword.text!
        let name = self.name.text!
        let age = self.age.text!
        let maleOrFemale: String
        if self.maleOrFemale.selectedSegmentIndex == 0 {
            maleOrFemale = "male"
        } else if self.maleOrFemale.selectedSegmentIndex == 1 {
            maleOrFemale = "female"
        } else {
            maleOrFemale = "none"
        }
        
        // Creates a new user and saves user info under the node /users/uid
        if password.characters.count >= 6 && retypePassword == password {
            if isValidEmail(email) {
                checkIfValidUsername(userName, vc: self, handler: { (isValid) in
                    if isValid {
                        if name.characters.count < 18 && name.characters.count > 0 && !checkForSpecialCharactersAndNumbers(name) {
                                // Check if username is free
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
                                                        let imageData = UIImageJPEGRepresentation(UIImage(named: "default_pic.png")!, 0.5)
                                                        if let data = imageData {
                                                            storageRef.child("profilePictures").child((FIRAuth.auth()?.currentUser?.uid)!).child("userPic").putData(data, metadata: nil) { (metaData, error) in
                                                                if let error = error {
                                                                    print(error.description)
                                                                } else {
                                                                    let userInfo = ["name": name, "username": userName, "age": age, "gender": maleOrFemale, "email":email, "privacy":false,"provider":"Firebase"]
                                                                    currentUser.setValue(userInfo)

                                                                    // Make sure user didnt change the number in the text field after the first one was verified
                                                                    // Make sure the number is verified
                                                                    if self.phoneNumberVerified && self.phoneNumberToSave != nil && self.phoneNumberToSave == self.phoneNumber.text {
                                                                        currentUser.updateChildValues(["phoneNumber": self.phoneNumberToSave!])
                                                                        rootRef.child("phoneNumbers").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(self.phoneNumberToSave!)
                                                                    }
                                                                    
                                                                    SwiftOverlays.removeAllBlockingOverlays()
                                                                    addedUserToBatch()
                                                                    self.performSegueWithIdentifier(.NewLogin, sender: nil)
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        print(error)
                                                    }
                                                })
                                            } else {
                                                print(error!)
                                                if error!.code == 17007 {
                                                    self.displayAlertWithMessage("The email address is already in use by another account.")
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
                            SwiftOverlays.removeAllBlockingOverlays()
                            self.displayAlertWithMessage("Please enter a name less than 18 characters long. Name must not contain special characters or numbers")
                        }
                    } else {
                        SwiftOverlays.removeAllBlockingOverlays()
                        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
                        alertView.showNotice("Error", subTitle: "Username isn't right length (5-12 chars), contains whitespace, contains invaild characters, or is already in use")
                        
                    }
                })
            } else {
                SwiftOverlays.removeAllBlockingOverlays()
                displayAlertWithMessage("Not a valid email.")
            }
        } else {
            SwiftOverlays.removeAllBlockingOverlays()
            // Alert user what the error was when attempting to create account
            if !(retypePassword == password) {
                displayAlertWithMessage("Passwords do not match.")
            } else {
                displayAlertWithMessage("Password must be 6 characters long.")
            }
        }
    }

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        createAndBindViewModel()
     
    }
    
    func presentValidationErrorMessage(String error: String?) {
        if let error = error {
            displayAlertWithMessage(error)
        }
        
    }
    
    private func createAndBindViewModel() {
        
        let viewModelInputs = CreateAccountInputs(name: name.rx_text, username: username.rx_text, email: emailText.rx_text, password: passwordText.rx_text, retypePassword: retypePassword.rx_text, date: datePickerView.rx_date)
        
        viewModel = CreateAccountViewModel(Inputs: viewModelInputs)
        
        bindName()
        bindEmail()
        bindUsername()
        bindPasswordFields()
        bindDatePicker()
        
        viewModel.isValidSignupInformtion?
            .bindTo(signupButton.rx_enabled)
            .addDisposableTo(dispoeBag)
    }
    
    func bindDatePicker() {
        viewModel.age?
            .subscribeNext({ (age) in
                self.age.text = age
            })
            .addDisposableTo(dispoeBag)
    }
    
    func bindName() {
        
        viewModel.isValidName?
            .subscribeNext({ (isValid) in
                self.name.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidNameMessage?
            .subscribeNext({ (message) in
                self.name.validationErrorMessage = message
            })
            .addDisposableTo(dispoeBag)
    }
    
    func bindUsername() {
        
        viewModel.isValidUsername?
            .subscribeNext({ (isValid) in
                self.username.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidUsernameMessage?
            .subscribeNext({ (message) in
                self.username.validationErrorMessage = message
            })
            .addDisposableTo(dispoeBag)
    }
    
    func bindEmail() {
        viewModel.isValidEmail?
            .subscribeNext({ (isValid) in
                self.emailText.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidEmailMessage?
            .subscribeNext({ (message) in
                self.emailText.validationErrorMessage = message
            })
            .addDisposableTo(dispoeBag)
    }
    
    func bindPasswordFields() {
        viewModel.isValidPassword?
            .subscribeNext({ (isValid) in
                self.passwordText.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidPasswordMessage?
            .subscribeNext({ (message) in
                self.passwordText.validationErrorMessage = message
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidRetypedPassword?
            .subscribeNext({ (isValid) in
                self.retypePassword.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(dispoeBag)
        
        viewModel.isValidRetypedPasswordMessage?
            .subscribeNext({ (message) in
                self.retypePassword.validationErrorMessage = message
            })
            .addDisposableTo(dispoeBag)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 750)
    }
    
    // MARK: - Helper functions for view
    func setUpView(){
        // Create datepicker for user to enter age. Will present when user activates age text field
        datePickerView = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.Date
        
        // Setting up the textfield delegates
        emailText.delegate = self
        emailText.validationDelegate = self
        
        passwordText.delegate = self
        passwordText.validationDelegate = self
        
        retypePassword.validationDelegate = self
        retypePassword.delegate = self
        
        name.delegate = self
        name.validationDelegate = self
        
        username.delegate = self
        username.validationDelegate = self
        
        age.delegate = self
        phoneNumber.delegate = self
        
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
//        if textField.isEqual(username) {
//            username.text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string.lowercaseString)
//            return false
//        }
        
        if textField.isEqual(phoneNumber) {
            return shouldPhoneNumberTextChangeHelperMethod(textField, range: range, string: string)
        }
        
        return true
    }

    func displayAlertWithMessage(message:String) {
        SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Error", subTitle: message)
    }

}
