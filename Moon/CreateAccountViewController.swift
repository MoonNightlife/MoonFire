//
//  CreateAccountViewController.swift
//  Moon
//
//  Created by Evan Noble on 12/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct CreateAccountInputs {
    let email: ControlProperty<String>
    let password: ControlProperty<String>
    let retypePassword: ControlProperty<String>
    let createAccountButtonTapped: ControlEvent<Void>
}

class CreateAccountViewController: UIViewController, UITextFieldDelegate, SegueHandlerType, ValidationTextFieldDelegate, ErrorPopoverRenderer, OverlayRenderer {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case EnterProfileInformation
    }
    
    @IBOutlet weak var emailText: ValidationTextField!
    @IBOutlet weak var passwordText: ValidationTextField!
    @IBOutlet weak var retypePassword: ValidationTextField!
    @IBOutlet weak var signupButton: UIButton!
    
    private var viewModel: CreateAccountViewModel!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
        createAndBindViewModel()

    }
    
    private func setUpView() {
        emailText.delegate = self
        emailText.validationDelegate = self
        
        passwordText.delegate = self
        passwordText.validationDelegate = self
        
        retypePassword.validationDelegate = self
        retypePassword.delegate = self
        
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordText.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        retypePassword.attributedPlaceholder = NSAttributedString(string:"Confirm Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        retypePassword.resignFirstResponder()
    }

    private func createAndBindViewModel() {
        
        let viewModelInputs = CreateAccountInputs(email: emailText.rx_text, password: passwordText.rx_text, retypePassword: retypePassword.rx_text, createAccountButtonTapped: signupButton.rx_tap)
        
        viewModel = CreateAccountViewModel(Inputs: viewModelInputs, backendService: FirebaseUserService(), validationService: ValidationService())
        
        bindPasswordFields()
        bindEmail()
        
        viewModel.isValidSignupInformtion?
            .bindTo(signupButton.rx_enabled)
            .addDisposableTo(disposeBag)
        
        viewModel.accountCreationComplete.asObservable()
            .subscribeNext { (complete) in
                if complete {
                    self.performSegueWithIdentifier(SegueIdentifier.EnterProfileInformation, sender: self)
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
    
    func presentValidationErrorMessage(String error: String?) {
        if let error = error {
            presentError(ErrorOptions(errorMessage: error))
        }
    }

}
