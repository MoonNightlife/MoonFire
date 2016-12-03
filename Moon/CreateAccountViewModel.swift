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
    
    let disposeBag = DisposeBag()
    
    // Model
    var newUser = CreateAccountModel()
    
    // Services
    //let firebaseService:
    
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
    
    
    init(Inputs inputs: CreateAccountInputs) {
        self.inputs = inputs
        setupTextValidation()
        subscribeToView()
        formatInputs()
    }
    
    private func setupTextValidation() {
        
        let validNameResponse = inputs.name
            .distinctUntilChanged()
            .doOnNext({ (name) in
                self.newUser.name = name
            })
            .map { return ValidationService.isValid(Name: $0) }
        
        isValidName = validNameResponse
            .map({$0.isValid})
        isValidNameMessage = validNameResponse
            .map({$0.Message})
        
        
        let validUsernameResponse = inputs.username
            .distinctUntilChanged()
            .doOnNext({ (username) in
                self.newUser.username = username
            })
            .map { ValidationService.isValid(Username: $0) }
        
        isValidUsername = validUsernameResponse
            .map({$0.isValid})
        isValidUsernameMessage = validUsernameResponse
            .map({$0.Message})
    
        
        let validEmailResponse = inputs.email
            .distinctUntilChanged()
            .doOnNext({ (email) in
                self.newUser.email = email
            })
            .map { ValidationService.isValid(Email: $0) }
        
        isValidEmail = validEmailResponse
            .map({$0.isValid})
        isValidEmailMessage = validEmailResponse
            .map({$0.Message})
        
        
        let validPasswordResponse = inputs.password
            .distinctUntilChanged()
            .doOnNext({ (password) in
                self.newUser.password = password
            })
            .map { ValidationService.isValid(Password: $0) }
        
        isValidPassword = validPasswordResponse
            .map({$0.isValid})
        isValidPasswordMessage = validPasswordResponse
            .map({$0.Message})
        
        let validRetypedPasswordResponse = inputs.retypePassword
            .map { ValidationService.isValid(Password: $0) }
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
    
    private func subscribeToView() {
        inputs.sex
            .subscribeNext { (sex) in
                switch sex {
                case 0:
                    self.newUser.sex = "male"
                case 1:
                    self.newUser.sex = "female"
                default:
                    self.newUser.sex = "none"
                }
            }
            .addDisposableTo(disposeBag)
        
        inputs.signupButtonTapped
            .subscribeNext {
                print(self.newUser)
                print("Logging In")
            }
            .addDisposableTo(disposeBag)
    }
    
    private func formatInputs() {
        birthday = inputs.birthday
            .distinctUntilChanged()
            .map({self.convertDateToString($0)})
            .doOnNext({ (birthday) in
                self.newUser.birthday = birthday
            })
    }
    
    private func convertDateToString(date: NSDate) -> String {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        return dateFormatter.stringFromDate(date)
        
    }
}


