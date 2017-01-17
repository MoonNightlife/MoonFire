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
    
    // Services
    private var smsValidationService: SMSValidationService!
    private var userBackendService: UserAccountBackendService!
    
    // Inputs
    let phoneNumber = BehaviorSubject<String>(value: "")
    let sendVerificationButtonTapped = PublishSubject<Void>()
    let verificationCode = BehaviorSubject<String>(value: "")
    let verifyButtonTapped = PublishSubject<Void>()
    
    // Outputs
    var verificationCodeSent = Variable<Bool>(false)
    var validationComplete = Variable<Bool>(false)
    
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    
    var formattedVerificationCode: Observable<String> {
        return verificationCode
                .map({
                    return self.formatValidationCode($0)
                })

    }
    
    var isValidCode: Observable<Bool> {
        return formattedVerificationCode
            .map({
                return ($0.characters.count == 4)
            })
    }
    
    
    var formattedForStoragePhoneNumber: Observable<String> {
        return phoneNumber
            .map({self.smsValidationService.formatPhoneNumberForStorageFrom(String: $0) ?? $0})
    }
    
    var formattedForGuiPhoneNumber: Observable<String> {
        return phoneNumber
            .map({self.smsValidationService.formatPhoneNumberForGuiFrom(String: $0) ?? $0 })
    }
    
    var isValidPhoneNumber: Observable<Bool> {
        return phoneNumber
            .map({$0.characters.count > 1})
    }
    

    
    var phoneNumberChangedFromSentPhoneNumber: Observable<Bool> {
        return Observable.combineLatest(self.phoneNumberVerificationSentTo.asObservable(), self.formattedForStoragePhoneNumber.asObservable()) {
            return ($0 == $1)
        }
    }
    
    init(smsValidationService: SMSValidationService, userBackendService: UserAccountBackendService) {
        self.smsValidationService = smsValidationService
        self.userBackendService = userBackendService
        
        subscribeToInputs()
        
    }

    private func subscribeToInputs() {
    
        sendVerificationButtonTapped
            .withLatestFrom(self.formattedForStoragePhoneNumber)
            .filter {
                if $0 == self.phoneNumberVerificationSentTo.value {
                    self.errorMessageToDisplay.value = "Code already sent to this number"
                    return false
                }
                return true
            }
            .doOnNext({
                self.shouldShowOverlay.value = .Show(options: OverlayOptions(message: "Sending Verification SMS", type: .Blocking))
                self.phoneNumberVerificationSentTo.value = $0
            })
            .flatMapFirst({ (phoneNumberForStorage) -> Observable<SMSValidationResponse> in
                return self.smsValidationService.sendVerificationCodeTo(PhoneNumber: phoneNumberForStorage)
            })
            .subscribeNext {
                self.shouldShowOverlay.value = .Remove
                switch $0 {
                case .Success:
                    self.verificationCodeSent.value = true
                case .Error(let error):
                    self.verificationCodeSent.value = false
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            }
            .addDisposableTo(disposeBag)

        
        verifyButtonTapped
            .doOnNext({ (_) in
                self.shouldShowOverlay.value = .Show(options: OverlayOptions(message: "Verifying Code", type: .Blocking))
            })
            .withLatestFrom(formattedVerificationCode)
            .flatMapFirst({ (code) -> Observable<BackendResponse> in
                return self.verifyCode(code)
            })
            .subscribeNext { response in
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

    private func verifyCode(code: String) -> Observable<BackendResponse> {
        return smsValidationService.verifyNumberWith(Code: code)
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
    }
    
    private func formatValidationCode(code: String) -> String {
        if code.characters.count >= 4 {
            return code.substringToIndex(code.startIndex.advancedBy(4))
        } else {
            return code
        }
    }
    
}