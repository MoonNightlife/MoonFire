//
//  CreateAccountViewModel.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ObjectMapper

struct CreateAccountInputs {
    let name: ControlProperty<String>
    let username: ControlProperty<String>
    let email: ControlProperty<String>
    let password: ControlProperty<String>
    let retypePassword: ControlProperty<String>
    let birthday: ControlProperty<NSDate>
    let signupButtonTapped: ControlEvent<Void>
    let sex: ControlProperty<Int>
    let phoneNumber: ControlProperty<String>
}


class CreateAccountViewModel {
    
    // Properties
    private let disposeBag = DisposeBag()
    private var newUser: User2
    
    // Services
    private let backendService: BackendService!
    private let validationService: AccountValidation!
    private let photoBackendService: PhotoBackendService!
    
    // Inputs
    let inputs: CreateAccountInputs!
    
    // Output
    var isValidSignupInformtion: Observable<Bool>?
    var doPasswordEntriesMatch: Observable<Bool>?
    
    var isValidName: Observable<Bool>?
    var isValidNameMessage: Observable<String>?
    
    var isValidUsername: Observable<Bool>?
    var isValidUsernameMessage: Observable<String>?
    
    var isValidEmail: Observable<Bool>?
    var isValidEmailMessage: Observable<String>?
    
    var isValidPassword: Observable<Bool>?
    var isValidPasswordMessage: Observable<String>?
    
    var isValidRetypedPassword: Observable<Bool>?
    var isValidRetypedPasswordMessage: Observable<String>?
    
    var birthday: Observable<String>?
    var signUpComplete = Variable<Bool>(false)
    
    init(Inputs inputs: CreateAccountInputs, backendService: BackendService, validationService: AccountValidation, photoBackendService: PhotoBackendService) {
        
        self.inputs = inputs
        self.backendService = backendService
        self.validationService = validationService
        self.photoBackendService = photoBackendService
        self.newUser = User2()
        
        createOutputs()
        subscribeToInputs()
        formatInputs()
    }
    
    private func createOutputs() {
        
        let validNameResponse = inputs.name
            .distinctUntilChanged()
            .doOnNext({ (name) in
                self.newUser.name = name
            })
            .map { return self.validationService.isValid(Name: $0) }
        
        isValidName = validNameResponse
            .map({$0.isValid})
        isValidNameMessage = validNameResponse
            .map({$0.Message})
        
        
        let validUsernameResponse = inputs.username
            .distinctUntilChanged()
            .doOnNext({ (username) in
                self.newUser.username = username
            })
            .map { self.validationService.isValid(Username: $0) }
        
        isValidUsername = validUsernameResponse
            .map({$0.isValid})
        isValidUsernameMessage = validUsernameResponse
            .map({$0.Message})
    
        
        let validEmailResponse = inputs.email
            .distinctUntilChanged()
            .doOnNext({ (email) in
                self.newUser.email = email
            })
            .map { self.validationService.isValid(Email: $0) }
        
        isValidEmail = validEmailResponse
            .map({$0.isValid})
        isValidEmailMessage = validEmailResponse
            .map({$0.Message})
        
        
        let validPasswordResponse = inputs.password
            .distinctUntilChanged()
            .doOnNext({ (password) in
                self.newUser.password = password
            })
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
            .combineLatest(validNameResponse, validPasswordResponse, validEmailResponse, validUsernameResponse, validRetypedPasswordResponse, doPasswordsMatch) {
                return $0.0 && $1.0 && $2.0 && $3.0 && $4.0 && $5
            }

    }
    
    private func subscribeToInputs() {
        inputs.sex
            .subscribeNext { (sex) in
                self.newUser.sex = Sex(rawValue: sex)
            }
            .addDisposableTo(disposeBag)
        
        inputs.signupButtonTapped
            .subscribeNext {
                self.createAccount()
            }
            .addDisposableTo(disposeBag)
    }
    
    private func formatInputs() {
        birthday = inputs.birthday
            .distinctUntilChanged()
            .map({$0.convertDateToMediumStyleString()})
            .doOnNext({ (birthday) in
                self.newUser.birthday = birthday
            })
    }
    
    private func createAccount() {
        if let email = newUser.email, let password = newUser.password {
            
            let credentials = ProviderCredentials.Email(credentials: EmailCredentials(email: email, password: password))
            backendService.createAccount(credentials)
                .doOnNext({ (uid) in
                    self.newUser.userId = uid
                    self.newUser.provider = .Firebase
                    // Need to remove this once the rest of the app is refactored, we are no longer storing the uid in NSUserDefault
                    NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
                })
                .flatMapLatest({ (uid) in
                    return self.photoBackendService.saveProfilePicture(uid, image: UIImage(named: "default_pic.png")!)
                })
                .subscribeNext({ (response) in
                    if response {
                        self.backendService.saveUser(self.newUser)
                        self.signUpComplete.value = true
                    }
                })
                .addDisposableTo(disposeBag)
        }
    }

}


