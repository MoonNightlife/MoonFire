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

class CreateAccountViewController: UIViewController, UITextFieldDelegate, SegueHandlerType, ValidationTextFieldDelegate, ErrorPopoverRenderer, OverlayRenderer {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case EnterPhoneNumber
    }
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailText: ValidationTextField!
    @IBOutlet weak var passwordText: ValidationTextField!
    @IBOutlet weak var username: ValidationTextField!
    @IBOutlet weak var retypePassword: ValidationTextField!
    @IBOutlet weak var name: ValidationTextField!
    @IBOutlet weak var sex: UISegmentedControl!
    @IBOutlet weak var birthday: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var phoneNumber: ValidationTextField!
    @IBOutlet weak var signupButton: UIButton!
    var datePickerView: UIDatePicker!

    private var viewModel: CreateAccountViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - Actions
    @IBAction func ageEditingStarted(sender: UITextField) {
        sender.inputView = datePickerView
    }
    
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        createAndBindViewModel()
     
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segueIdentifierForSegue(segue) == .EnterPhoneNumber {
            
        }
    }
    
    func presentValidationErrorMessage(String error: String?) {
        if let error = error {
            presentError(ErrorOptions(errorMessage: error))
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 750)
    }
    
    // MARK: - Helper functions for view
    func setupView(){
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
        
        phoneNumber.delegate = self
        phoneNumber.validationDelegate = self
        
        
        birthday.delegate = self
        
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordText.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        retypePassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        name.attributedPlaceholder = NSAttributedString(string:"Name", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        birthday.attributedPlaceholder = NSAttributedString(string:"Birthday", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
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
        birthday.resignFirstResponder()
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

    func displayAlertWithMessage(message:String) {
        SCLAlertView(appearance: K.Apperances.NormalApperance).showNotice("Error", subTitle: message)
    }

}

typealias CreateAccountRxSwiftFunctions = CreateAccountViewController
extension CreateAccountRxSwiftFunctions {
    
    private func createAndBindViewModel() {
        
        let viewModelInputs = CreateAccountInputs(name: name.rx_text, username: username.rx_text, email: emailText.rx_text, password: passwordText.rx_text, retypePassword: retypePassword.rx_text, birthday: datePickerView.rx_date, signupButtonTapped: signupButton.rx_tap, sex: sex.rx_value, phoneNumber: phoneNumber.rx_text)
        
        viewModel = CreateAccountViewModel(Inputs: viewModelInputs, backendService: FirebaseUserService(), validationService: ValidationService(), photoBackendService: FirebaseStorageService())
        
        bindName()
        bindEmail()
        bindUsername()
        bindPasswordFields()
        bindDatePicker()
        
        viewModel.signUpComplete.asObservable()
            .subscribeNext { (completed) in
                if completed {
                    self.performSegueWithIdentifier(.EnterPhoneNumber, sender: self)
                }
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
        
        viewModel.errorMessageToDisplay.asObservable()
            .subscribeNext { (errorMessage) in
                guard let message = errorMessage else {
                    return
                }
                self.presentError(ErrorOptions(errorMessage: message))
            }
            .addDisposableTo(disposeBag)
        

        viewModel.isValidSignupInformtion?
            .bindTo(signupButton.rx_enabled)
            .addDisposableTo(disposeBag)
    }
    
    private func bindDatePicker() {
        
        viewModel.birthday?
            .subscribeNext({ (birthday) in
                self.birthday.text = birthday
            })
            .addDisposableTo(disposeBag)
    }
    
    private func bindName() {
        
        viewModel.isValidName?
            .subscribeNext({ (isValid) in
                self.name.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidNameMessage?
            .subscribeNext({ (message) in
                self.name.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
    }
    
    private func bindUsername() {
        
        viewModel.isValidUsername?
            .subscribeNext({ (isValid) in
                self.username.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidUsernameMessage?
            .subscribeNext({ (message) in
                self.username.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
    }
    
    private func bindEmail() {
        viewModel.isValidEmail?
            .subscribeNext({ (isValid) in
                self.emailText.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidEmailMessage?
            .subscribeNext({ (message) in
                self.emailText.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
    }
    
    private func bindPasswordFields() {
        
        viewModel.isValidPassword?
            .subscribeNext({ (isValid) in
                self.passwordText.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidPasswordMessage?
            .subscribeNext({ (message) in
                self.passwordText.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidRetypedPassword?
            .subscribeNext({ (isValid) in
                self.retypePassword.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidRetypedPasswordMessage?
            .subscribeNext({ (message) in
                self.retypePassword.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
        
    }
}
