//
//  PhoneNumberEntryViewController.swift
//  Moon
//
//  Created by Evan Noble on 12/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class PhoneNumberEntryViewController: UIViewController, ErrorPopoverRenderer, SegueHandlerType, OverlayRenderer {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case NewLogin
    }
   
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var sendVerificationButton: UIButton!
    @IBOutlet weak var verificationCodeTextField: UITextField!
    @IBOutlet weak var verifyCodeButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    
    private var viewModel: PhoneNumberEntryViewModel!
    private let disposeBag = DisposeBag()
    var partOfSignUpFlow = true

    override func viewDidLoad() {
        super.viewDidLoad()

        bindAndCreateViewModel()
        setupView()
    }
    
    private func bindAndCreateViewModel() {
        
        
        viewModel = PhoneNumberEntryViewModel(smsValidationService: SinchService(), userBackendService: FirebaseUserAccountService())
        
        cancelButton.rx_tap
            .subscribeNext {
                self.performSegueWithIdentifier(.NewLogin, sender: nil)
            }
            .addDisposableTo(disposeBag)
        
        // VC to VM
        phoneNumberTextField.rx_text.bindTo(viewModel.phoneNumber).addDisposableTo(disposeBag)
        sendVerificationButton.rx_tap.bindTo(viewModel.sendVerificationButtonTapped).addDisposableTo(disposeBag)
        verificationCodeTextField.rx_text.bindTo(viewModel.verificationCode).addDisposableTo(disposeBag)
        verifyCodeButton.rx_tap.bindTo(viewModel.verifyButtonTapped).addDisposableTo(disposeBag)
        
        // VM to VC
        viewModel.formattedVerificationCode.bindTo(verificationCodeTextField.rx_text).addDisposableTo(disposeBag)
        bindViewModel()
        
        
    }
    
    private func bindViewModel() {
        
        viewModel.formattedForGuiPhoneNumber.asObservable().bindTo(phoneNumberTextField.rx_text).addDisposableTo(disposeBag)
        viewModel.formattedVerificationCode.asObservable().bindTo(verificationCodeTextField.rx_text).addDisposableTo(disposeBag)
        viewModel.isValidPhoneNumber.bindTo(sendVerificationButton.rx_enabled).addDisposableTo(disposeBag)
        
        viewModel.validationComplete.asObservable()
            .subscribeNext {
                if $0 {
                    self.performSegueWithIdentifier(.NewLogin, sender: nil)
                }
            }
            .addDisposableTo(disposeBag)
        
        Observable.combineLatest(viewModel.verificationCodeSent.asObservable(), viewModel.phoneNumberChangedFromSentPhoneNumber) {
            return ($0 && $1)
            }.subscribeNext { (enabled) in
                self.verificationCodeTextField.enabled = enabled
                if enabled {
                     self.verificationCodeTextField.attributedPlaceholder = NSAttributedString(string:"Code", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
                } else {
                    self.verificationCodeTextField.attributedPlaceholder = NSAttributedString(string:"Code", attributes:[NSForegroundColorAttributeName: UIColor.lightTextColor()])
                }
                
                if !enabled {
                    // Must send these actions when changing the text field manually or the obserable sequence doesnt emit a value
                    self.verificationCodeTextField.sendActionsForControlEvents(.EditingDidBegin)
                    self.verificationCodeTextField.text = ""
                    self.verificationCodeTextField.sendActionsForControlEvents(.EditingDidEnd)
                }
            }
            .addDisposableTo(disposeBag)
        
        Observable.combineLatest(viewModel.isValidCode, viewModel.verificationCodeSent.asObservable(),viewModel.phoneNumberChangedFromSentPhoneNumber) {
            return ($0 && $1 && $2)
            }.subscribeNext { (isVerifyButtonEnabled) in
                self.verifyCodeButton.enabled = isVerifyButtonEnabled
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
        
    }

    
    private func setupView() {
        
        if !partOfSignUpFlow {
            //TODO: Add more style changes to view to make it more like the settings themes
            cancelButton.hidden = true
            cancelButton.userInteractionEnabled = false
        }
        
        
        phoneNumberTextField.attributedPlaceholder = NSAttributedString(string:"Phone Number", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
       self.verificationCodeTextField.attributedPlaceholder = NSAttributedString(string:"Code", attributes:[NSForegroundColorAttributeName: UIColor.lightTextColor()])
    }


}