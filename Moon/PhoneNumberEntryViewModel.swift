//
//  PhoneNumberEntryViewModel.swift
//  Moon
//
//  Created by Evan Noble on 12/6/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

class PhoneNumberEntryViewModel {
    
    // Properties
    private let disposeBag = DisposeBag()
    private var phoneNumberVerificationSentTo = Variable<String>("")
    private var userModel: User2!
    
    // Services
    private var smsValidationService: SMSValidationService!
    private var userBackendService: UserBackendService!
    
    // Inputs
    private var inputs: PhoneNumberEntryInputs! 
    
    // Outputs
    var verificationCodeSent = Variable<Bool>(false)
    var validationComplete = Variable<Bool>(false)
    
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    
    var formattedVerificationCode = Variable<String>("")
    var formattedForStoragePhoneNumber = Variable<String>("")
    
    var formattedForGuiPhoneNumber: Observable<String> {
        return inputs.phoneNumber
            .map({self.smsValidationService.formatPhoneNumberForGuiFrom(String: $0) ?? $0 })
    }
    
    var isValidPhoneNumber: Observable<Bool> {
        return inputs.phoneNumber
            .map({$0.characters.count > 1})
    }
    
    var isValidCode: Observable<Bool> {
        return inputs.verificationCode
            .map({($0.characters.count == 4)})
    }
    
    var phoneNumberChangedFromSentPhoneNumber: Observable<Bool> {
        return Observable.combineLatest(self.phoneNumberVerificationSentTo.asObservable(), self.formattedForStoragePhoneNumber.asObservable()) {
            return ($0 == $1)
        }
    }
    
    init(smsValidationService: SMSValidationService, inputs: PhoneNumberEntryInputs, userBackendService: UserBackendService) {
        self.smsValidationService = smsValidationService
        self.userBackendService = userBackendService
        self.inputs = inputs
        
        subscribeToInputs()
        
    }

    private func subscribeToInputs() {
        
        inputs.phoneNumber
            .map({self.smsValidationService.formatPhoneNumberForStorageFrom(String: $0) ?? $0 })
            .bindTo(formattedForStoragePhoneNumber)
            .addDisposableTo(disposeBag)
    
        inputs.sendVerificationButtonTapped
            .filter {
                if self.formattedForStoragePhoneNumber.value == self.phoneNumberVerificationSentTo.value {
                    self.errorMessageToDisplay.value = "Code already sent to this number"
                    return false
                }
                return true
            }
            .subscribeNext {
                self.shouldShowOverlay.value = .Show(options: OverlayOptions(message: "Sending Verification SMS", type: .Blocking))
                self.sendVerificaionCodeToUsersPhoneNumber()
            }
            .addDisposableTo(disposeBag)
        
        inputs.verificationCode
            .map({self.formatValidationCode($0)})
            .bindTo(formattedVerificationCode)
            .addDisposableTo(disposeBag)

        
        inputs.verifyButtonTapped
            .subscribeNext {
                self.shouldShowOverlay.value = .Show(options: OverlayOptions(message: "Verifying Code", type: .Blocking))
                self.verifyCode()
            }
            .addDisposableTo(disposeBag)
        
    }
    
    private func sendVerificaionCodeToUsersPhoneNumber() {
        smsValidationService.sendVerificationCodeTo(PhoneNumber: formattedForStoragePhoneNumber.value)
            .subscribeNext({
                self.shouldShowOverlay.value = .Remove
                switch $0 {
                case .Success:
                    self.phoneNumberVerificationSentTo.value = self.formattedForStoragePhoneNumber.value
                    self.verificationCodeSent.value = true
                case .Error(let error):
                    self.verificationCodeSent.value = false
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            })
            .addDisposableTo(disposeBag)
    }

    private func verifyCode() {
        smsValidationService.verifyNumberWith(Code: formattedVerificationCode.value)
            .filter({ (smsResponse) -> Bool in
                switch smsResponse {
                case .Error(let error):
                    self.shouldShowOverlay.value = .Remove
                    self.errorMessageToDisplay.value = error.debugDescription
                    return false
                case .Success:
                    return true
                }
            })
            .flatMapLatest { (_) -> Observable<BackendResponse> in
                return self.userBackendService.savePhoneNumber(self.phoneNumberVerificationSentTo.value)
            }
            .subscribeNext { (response) in
                self.shouldShowOverlay.value = .Remove
                switch response {
                case .Success:
                    self.validationComplete.value = true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    private func formatValidationCode(code: String) -> String {
        if code.characters.count > 4 {
            return code.substringToIndex(code.startIndex.advancedBy(4))
        } else {
            return code
        }
    }
    
}