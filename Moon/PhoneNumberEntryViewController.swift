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

class PhoneNumberEntryViewController: UIViewController, ErrorPopoverRenderer {
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var sendVerificationButton: UIButton!
    @IBOutlet weak var verificationCodeTextField: UITextField!
    @IBOutlet weak var verifyCodeButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var viewModel: PhoneNumberEntryViewModel!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createAndBindViewModel()
        bindView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

typealias PhoneNumberEntryRxSwiftFunctions = PhoneNumberEntryViewController
extension PhoneNumberEntryRxSwiftFunctions {
    private func bindView() {
        cancelButton.rx_tap
            .subscribeNext {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            .addDisposableTo(disposeBag)
        
    }
    
    private func createAndBindViewModel() {
        let viewModelInputs = PhoneNumberEntryInputs(phoneNumber: phoneNumberTextField.rx_text, sendVerificationButtonTapped: sendVerificationButton.rx_tap, verificationCode: verificationCodeTextField.rx_text, verifyButtonTapped: verifyCodeButton.rx_tap)
        
        viewModel = PhoneNumberEntryViewModel(inputs: viewModelInputs, smsValidationService: SinchService())
        
        viewModel.isValidPhoneNumber?
            .bindTo(sendVerificationButton.rx_enabled)
            .addDisposableTo(disposeBag)
        
        viewModel.verificationCodeSent.asObservable()
            .bindTo(verificationCodeTextField.rx_enabled)
            .addDisposableTo(disposeBag)
        
        viewModel.verificationCodeSent.asObservable()
            .bindTo(verifyCodeButton.rx_enabled)
            .addDisposableTo(disposeBag)
        
        viewModel.validationComplete.asObservable()
            .subscribeNext({
                if $0 {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }).addDisposableTo(disposeBag)
        
        viewModel.errorMessageToDisplay.asObservable()
            .subscribeNext { (errorMessage) in
                guard let message = errorMessage else {
                    return
                }
                self.presentError(ErrorOptions(errorMessage: message))
            }
            .addDisposableTo(disposeBag)
    }
}
