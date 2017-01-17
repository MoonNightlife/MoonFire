//
//  CreateAccountViewModel.swift
//  Moon
//
//  Created by Evan Noble on 12/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

class CreateAccountViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Services
    private let userBackendService: UserAccountBackendService!
    private let validationService: AccountValidation!
    
    // Inputs
    var email = BehaviorSubject<String>(value: "")
    var password = BehaviorSubject<String>(value: "")
    var retypePassword = BehaviorSubject<String>(value: "")
    var createAccountButtonTapped = PublishSubject<Void>()
    
    // Outputs
    var isValidEmail: Observable<Bool>?
    var isValidEmailMessage: Observable<String>?
    
    var isValidPassword: Observable<Bool>?
    var isValidPasswordMessage: Observable<String>?
    
    var isValidRetypedPassword: Observable<Bool>?
    var isValidRetypedPasswordMessage: Observable<String>?
    
    var isValidSignupInformtion: Observable<Bool>?
    var doPasswordEntriesMatch: Observable<Bool>?
    
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    var accountCreationComplete: Observable<Bool>!
    
    init(backendService: UserAccountBackendService, validationService: AccountValidation) {
        
        self.userBackendService = backendService
        self.validationService = validationService
        
        createOutputs()
    }
    
    private func createOutputs() {
        
        let credentials = Observable.combineLatest(email, password) { (email, password) in
            return EmailCredentials(email: email, password: password)
        }
        
        accountCreationComplete = createAccountButtonTapped
            .withLatestFrom(credentials)
            .flatMapFirst({ (credentials) -> Observable<BackendResponse> in
                self.userBackendService.createAccount(ProviderCredentials.Email(credentials: credentials))
            })
            .map({
                switch $0 {
                case .Success:
                    return true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                    return false
                }
            })
            .filter({$0})
        
        let validEmailResponse = email
            .map { self.validationService.isValid(Email: $0) }
        
        isValidEmail = validEmailResponse
            .map({$0.isValid})
        isValidEmailMessage = validEmailResponse
            .map({$0.Message})
        
        
        let validPasswordResponse = password
            .map { self.validationService.isValid(Password: $0) }
        
        isValidPassword = validPasswordResponse
            .map({$0.isValid})
        isValidPasswordMessage = validPasswordResponse
            .map({$0.Message})
        
        let validRetypedPasswordResponse = retypePassword
            .map { self.validationService.isValid(Password: $0) }
        let doPasswordsMatch = Observable
            .combineLatest(password, retypePassword) {
                return ($0 == $1)
        }
        isValidRetypedPassword = Observable
            .combineLatest(validRetypedPasswordResponse, doPasswordsMatch) {
                return $0.0 && $1
        }
        isValidRetypedPasswordMessage = validRetypedPasswordResponse
            .map({$0.Message})
        
        isValidSignupInformtion = Observable
            .combineLatest(validPasswordResponse, validEmailResponse, validRetypedPasswordResponse, doPasswordsMatch) {
                return $0.0 && $1.0 && $2.0 && $3
        }

    }

    
}