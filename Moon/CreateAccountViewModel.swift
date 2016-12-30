//
//  CreateAccountViewModel.swift
//  Moon
//
//  Created by Evan Noble on 12/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ObjectMapper

struct CreateAccountInputs {
    let email: ControlProperty<String>
    let password: ControlProperty<String>
    let retypePassword: ControlProperty<String>
    let createAccountButtonTapped: ControlEvent<Void>
}

class CreateAccountViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Inputs
    let inputs: CreateAccountInputs!
    
    // Services
    private let userBackendService: UserBackendService!
    private let validationService: AccountValidation!
    
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
    var accountCreationComplete = Variable<(Bool)>(false)
    
    init(Inputs inputs: CreateAccountInputs, backendService: UserBackendService, validationService: AccountValidation) {
        
        self.inputs = inputs
        self.userBackendService = backendService
        self.validationService = validationService
        
        createOutputs()
        subscribeToInputs()
    }
    
    private func subscribeToInputs() {
        
        let credentials = Observable.combineLatest(inputs.email, inputs.password) { (email, password) in
            return EmailCredentials(email: email, password: password)
        }
        
        inputs.createAccountButtonTapped
            .withLatestFrom(credentials)
            .flatMapFirst({ (credentials) in
                self.userBackendService.createAccount(ProviderCredentials.Email(credentials: credentials))
            })
            .subscribeNext({ (results) in
                switch results {
                case .Success:
                    self.accountCreationComplete.value = true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.rawValue
                }
            })
            .addDisposableTo(disposeBag)
        
    }
    
    private func createOutputs() {
        
        let validEmailResponse = inputs.email
            .map { self.validationService.isValid(Email: $0) }
        
        isValidEmail = validEmailResponse
            .map({$0.isValid})
        isValidEmailMessage = validEmailResponse
            .map({$0.Message})
        
        
        let validPasswordResponse = inputs.password
            .map { self.validationService.isValid(Password: $0) }
        
        isValidPassword = validPasswordResponse
            .map({$0.isValid})
        isValidPasswordMessage = validPasswordResponse
            .map({$0.Message})
        
        let validRetypedPasswordResponse = inputs.retypePassword
            .map { self.validationService.isValid(Password: $0) }
        let doPasswordsMatch = Observable
            .combineLatest(inputs.password, inputs.retypePassword) {
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