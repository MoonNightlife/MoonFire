//
//  CreateAccountViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class EnterProfileInformationViewController: UIViewController, UITextFieldDelegate, SegueHandlerType, ValidationTextFieldDelegate, ErrorPopoverRenderer, OverlayRenderer {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case EnterPhoneNumber
        case ProfileEntryCancelled
    }
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var username: ValidationTextField!
    @IBOutlet weak var firstName: ValidationTextField!
    @IBOutlet weak var lastName: ValidationTextField!
    @IBOutlet weak var sex: UISegmentedControl!
    @IBOutlet weak var birthday: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var profilePicture: UIImageView!
    var datePickerView: UIDatePicker!

    private var viewModel: EnterProfileInformationViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - Actions
    @IBAction func cancelCreationOfAccount(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.hidden = true
        
        setupView()
        createAndBindViewModel()
     
    }
    
    func presentValidationErrorMessage(String error: String?) {
        if let error = error {
            presentError(ErrorOptions(errorMessage: error))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 750)
    }
    
    // MARK: - Helper functions for view
    func setupView(){
        
        birthday.rx_controlEvent(.EditingDidBegin)
            .subscribeNext {
                self.birthday.inputView = self.datePickerView
            }
            .addDisposableTo(disposeBag)
        
        // Create datepicker for user to enter age. Will present when user activates age text field
        datePickerView = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.Date
        
        // Setting up the textfield delegates
        firstName.delegate = self
        firstName.validationDelegate = self
        
        lastName.delegate = self
        lastName.validationDelegate = self
        
        username.delegate = self
        username.validationDelegate = self
        
        birthday.delegate = self
        
        firstName.attributedPlaceholder = NSAttributedString(string:"First Name", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        lastName.attributedPlaceholder = NSAttributedString(string:"Last Name", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        birthday.attributedPlaceholder = NSAttributedString(string:"Birthday", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        username.attributedPlaceholder = NSAttributedString(string:"Username", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        // Scroll view
//        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 677)
//        scrollView.scrollEnabled = true
//        scrollView.backgroundColor = UIColor.clearColor()
        
    }
    

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
        
        //resigns the keyboards when it senses a touch

        firstName.resignFirstResponder()
        lastName.resignFirstResponder()
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
    
    private func createAndBindViewModel() {
        
        viewModel = EnterProfileInformationViewModel(backendService: FirebaseUserAccountService(), validationService: ValidationService(), photoBackendService: FirebaseStorageService(), facebookService: FacebookService(), photoUtilities: KingFisherUtilities())
        
        // VC to VM
        firstName.rx_text.bindTo(viewModel.firstNameInput).addDisposableTo(disposeBag)
        lastName.rx_text.bindTo(viewModel.lastNameInput).addDisposableTo(disposeBag)
        username.rx_text.bindTo(viewModel.username).addDisposableTo(disposeBag)
        datePickerView.rx_date.bindTo(viewModel.birthday).addDisposableTo(disposeBag)
        nextButton.rx_tap.bindTo(viewModel.nextButtonTapped).addDisposableTo(disposeBag)
        cancelButton.rx_tap.bindTo(viewModel.cancelledButtonTapped).addDisposableTo(disposeBag)
        sex.rx_value.bindTo(viewModel.sex).addDisposableTo(disposeBag)
        
        // VM to VC
        bindName()
        bindUsername()
        
        viewModel.signUpComplete.asObservable()
            .subscribeNext { (completed) in
                if completed {
                    self.performSegueWithIdentifier(.EnterPhoneNumber, sender: self)
                }
            }
            .addDisposableTo(disposeBag)
        
        viewModel.signUpCancelled?
            .subscribeNext({ (cancelled) in
                if cancelled {
                    self.performSegueWithIdentifier(.ProfileEntryCancelled, sender: self)
                }
            })
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
        
        
        viewModel.isValidSignupInformtion?.bindTo(nextButton.rx_enabled).addDisposableTo(disposeBag)
        viewModel.profilePicture.asObservable().bindTo(profilePicture.rx_image).addDisposableTo(disposeBag)
        viewModel.birthdayString?.bindTo(birthday.rx_text).addDisposableTo(disposeBag)
    }
    
    private func bindName() {
        
        viewModel.firstName.asObservable().bindTo(firstName.rx_text).addDisposableTo(disposeBag)
        viewModel.lastName.asObservable().bindTo(lastName.rx_text).addDisposableTo(disposeBag)
        
        viewModel.isValidFirstName?
            .subscribeNext({ (isValid) in
                self.firstName.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidFirstNameMessage?
            .subscribeNext({ (message) in
                self.firstName.validationErrorMessage = message
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidLastName?
            .subscribeNext({ (isValid) in
                self.lastName.changeRightViewToGreenCheck(isValid)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.isValidLastNameMessage?
            .subscribeNext({ (message) in
                self.lastName.validationErrorMessage = message
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

}
    

    

