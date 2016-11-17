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
}


class CreateAccountViewModel {
    
    // Services
    //let firebaseService:
    
    // Output
    var isValidSignupInformtion: Observable<Bool>?
    var isValidNameMessage: Observable<String?>?
    var isValidUsernameMessage: Observable<String?>?
    
    
    init(Inputs inputs: CreateAccountInputs) {
        setupTextHandlingWith(Inputs: inputs)
    }
    
    private func setupTextHandlingWith(Inputs inputs: CreateAccountInputs) {
        
        let validName = inputs.name
            .map { ValidationService.isValid(Name: $0) }
        isValidNameMessage = validName.map({$0.Message})
        
        let validUsername = inputs.username
            .map { ValidationService.isValid(Username: $0) }
        isValidUsernameMessage = validUsername.map({$0.Message})
        
        isValidSignupInformtion = Observable.combineLatest(validName, validUsername) {
            $0.0 && $1.0
        }
        
    }
}


