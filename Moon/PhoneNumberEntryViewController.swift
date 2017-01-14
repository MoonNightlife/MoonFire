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

struct PhoneNumberEntryInputs {
    let phoneNumber: ControlProperty<String>
    let sendVerificationButtonTapped: ControlEvent<Void>
    let verificationCode: ControlProperty<String>
    let verifyButtonTapped: ControlEvent<Void>
}

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //RxSwift
        let inputs = PhoneNumberEntryInputs(phoneNumber: phoneNumberTextField.rx_text, sendVerificationButtonTapped: sendVerificationButton.rx_tap, verificationCode: verificationCodeTextField.rx_text, verifyButtonTapped: verifyCodeButton.rx_tap)
        
        viewModel = PhoneNumberEntryViewModel(smsValidationService: SinchService(), inputs: inputs, userBackendService: FirebaseUserService())

        bindViewModel()
        bindView()
        setupView()
    }
    
    private func setupView() {
        phoneNumberTextField.attributedPlaceholder = NSAttributedString(string:"Phone Number", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        verificationCodeTextField.attributedPlaceholder = NSAttributedString(string:"Code", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
    }


}

typealias PhoneNumberEntryRxSwiftFunctions = PhoneNumberEntryViewController
extension PhoneNumberEntryRxSwiftFunctions {
    
    private func bindView() {
        cancelButton.rx_tap
            .subscribeNext {
                self.performSegueWithIdentifier(.NewLogin, sender: nil)
            }
            .addDisposableTo(disposeBag)
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
                    self.presentError(ErrorOptions())
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
}
