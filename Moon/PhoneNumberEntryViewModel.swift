//
//  PhoneNumberEntryViewModel.swift
//  Moon
//
//  Created by Evan Noble on 12/6/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct PhoneNumberEntryInputs {
    let phoneNumber: ControlProperty<String>
    let sendVerificationButtonTapped: ControlEvent<Void>
    let verificationCode: ControlProperty<String>
    let verifyButtonTapped: ControlEvent<Void>
}
class PhoneNumberEntryViewModel {
    
    let disposeBag = DisposeBag()
    
    // Model
    var phoneNumberEntry = PhoneNumberEntryModel()
    
    // Services
    var smsValidationService: SMSValidationService!
    
    // Inputs
    var inputs: PhoneNumberEntryInputs!
    
    // Outputs
    var verificationCodeSent = Variable<Bool>(false)
    var errorMessageToDisplay = Variable<String?>(nil)
    var validationComplete = Variable<Bool>(false)
    var formattedPhoneNumber: Observable<String>?
    var isValidPhoneNumber: Observable<Bool>?
    
    init(inputs: PhoneNumberEntryInputs, smsValidationService: SMSValidationService) {
        self.inputs = inputs
        self.smsValidationService = smsValidationService
    
        subscribeToInputs()
        createOutputs()
    }
    
    private func createOutputs() {
        isValidPhoneNumber = inputs.phoneNumber
            .doOnNext({ (phonenumber) in
            self.phoneNumberEntry.phoneNumber = phonenumber
            })
            .map { _ in true }
    }

    private func subscribeToInputs() {
        
        inputs.sendVerificationButtonTapped
            .subscribeNext {
                self.sendVerificaionCodeToUsersPhoneNumber()
            }
            .addDisposableTo(disposeBag)
        
        inputs.verifyButtonTapped
            .subscribeNext {
                self.verifyCode()
            }
            .addDisposableTo(disposeBag)
        
        inputs.verificationCode
            .subscribeNext { (code) in
                self.phoneNumberEntry.verificationCode = code
        }
        .addDisposableTo(disposeBag)
    }
    
    private func sendVerificaionCodeToUsersPhoneNumber() {
        guard let phoneNumber = self.phoneNumberEntry.phoneNumber else {
            return
        }
        self.smsValidationService.sendVerificationCodeTo(PhoneNumber: phoneNumber, CountryCode: "")
            .subscribe(onNext: { (response) in
                switch response {
                    case .Success:
                        self.verificationCodeSent.value = true
                    case .Error(let error):
                        self.verificationCodeSent.value = false
                        self.errorMessageToDisplay.value = error
                }
            })
            .addDisposableTo(self.disposeBag)
    }
    
    private func verifyCode() {
        guard let code = self.phoneNumberEntry.verificationCode else {
            return
        }
        self.smsValidationService.verifyNumberWith(Code: code)
            .subscribeNext { (response) in
                switch response {
                case .Success:
                    self.validationComplete.value = true
                case .Error(let error):
                    self.validationComplete.value = false
                    self.errorMessageToDisplay.value = error
                }
        }
        .addDisposableTo(disposeBag)
    }
    
}