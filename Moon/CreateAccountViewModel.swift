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
    let date: ControlProperty<NSDate>
}


class CreateAccountViewModel {
    
    // Services
    //let firebaseService:
    
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
    
    var age: Observable<String>?
    
    
    init(Inputs inputs: CreateAccountInputs) {
        setupTextHandlingWith(Inputs: inputs)
    }
    
    private func setupTextHandlingWith(Inputs inputs: CreateAccountInputs) {
        
        let validNameResponse = inputs.name
            .map { ValidationService.isValid(Name: $0) }
        isValidName = validNameResponse
            .map({$0.isValid})
        isValidNameMessage = validNameResponse
            .map({$0.Message})
        
        
        let validUsernameResponse = inputs.username
            .map { ValidationService.isValid(Username: $0) }
        isValidUsername = validUsernameResponse
            .map({$0.isValid})
        isValidUsernameMessage = validUsernameResponse
            .map({$0.Message})
    
        
        let validEmailResponse = inputs.email
            .map { ValidationService.isValid(Email: $0) }
        isValidEmail = validEmailResponse
            .map({$0.isValid})
        isValidEmailMessage = validEmailResponse
            .map({$0.Message})
        
        
        let validPasswordResponse = inputs.password
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
        
        age = inputs.date
            .map({self.convertDateToString($0)})
        
    }
    
    private func convertDateToString(date: NSDate) -> String {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        return dateFormatter.stringFromDate(date)
        
    }
}


