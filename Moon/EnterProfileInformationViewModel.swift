//
//  CreateAccountViewModel.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

class EnterProfileInformationViewModel {
    
    // Properties
    private let disposeBag = DisposeBag()
    
    // Services
    private let userBackendService: UserBackendService!
    private let validationService: AccountValidation!
    private let photoBackendService: PhotoBackendService!
    
    // Inputs
    let inputs: EnterProfileInformationInputs!
    
    // Output
    var isValidSignupInformtion: Observable<Bool>?
    var doPasswordEntriesMatch: Observable<Bool>?
    
    var isValidFirstName: Observable<Bool>?
    var isValidFirstNameMessage: Observable<String>?
    
    var isValidLastName: Observable<Bool>?
    var isValidLastNameMessage: Observable<String>?

    var isValidUsername: Observable<Bool>?
    var isValidUsernameMessage: Observable<String>?
    
    var birthday: Observable<String>?
    var signUpComplete = Variable<Bool>(false)
    var signUpCancelled: Observable<Bool>?
    
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    
    init(Inputs inputs: EnterProfileInformationInputs, backendService: UserBackendService, validationService: AccountValidation, photoBackendService: PhotoBackendService) {
        
        self.inputs = inputs
        self.userBackendService = backendService
        self.validationService = validationService
        self.photoBackendService = photoBackendService
        
        createOutputs()
        subscribeToInputs()
        formatInputs()
    }
    
    private func createOutputs() {
        
        let validFirstNameResponse = inputs.firstName
            .distinctUntilChanged()
            .map { return self.validationService.isValid(Name: $0) }
        
        isValidFirstName = validFirstNameResponse
            .map({$0.isValid})
        isValidFirstNameMessage = validFirstNameResponse
            .map({$0.Message})
        
        let validLastNameResponse = inputs.lastName
            .distinctUntilChanged()
            .map { return self.validationService.isValid(Name: $0) }
        
        isValidLastName = validLastNameResponse
            .map({$0.isValid})
        isValidLastNameMessage = validLastNameResponse
            .map({$0.Message})
        
        let validUsernameResponse = inputs.username
            .distinctUntilChanged()
            .map { self.validationService.isValid(Username: $0) }
        
        isValidUsername = validUsernameResponse
            .map({$0.isValid})
        isValidUsernameMessage = validUsernameResponse
            .map({$0.Message})
        
        isValidSignupInformtion = Observable
            .combineLatest(validFirstNameResponse, validLastNameResponse, validUsernameResponse) {
                return $0.0 && $1.0 && $2.0 
        }

    }
    
    private func subscribeToInputs() {
        let newUserInformation = Observable.combineLatest(inputs.firstName, inputs.lastName, inputs.username, inputs.birthday, inputs.sex) { (firstName, lastName, username, birthday, sex) in
                return (firstName, lastName, username, birthday, sex)
            }
        
        signUpCancelled = inputs.cancelledButtonTapped
            .flatMapFirst { (_) ->  Observable<BackendResponse> in
                return self.userBackendService.deleteAccountForSignedInUser()
            }
            .map({ (userDeleted) -> Bool in
                switch userDeleted {
                case .Success:
                    return true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                    return false
                }
            })
        
        
        inputs.nextButtonTapped
            .doOnNext({ 
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Saving profile information", type: .Blocking))
            })
            .withLatestFrom(newUserInformation)
            .flatMapFirst({ (firstName, lastName, username, birthday, sex) -> Observable<BackendResponse> in
                
                // When a user is created from init then a userSnapshot and userProfile are always created
                var newUser: User2 = User2()
                newUser.userSnapshot!.firstName = firstName
                newUser.userSnapshot!.lastName = lastName
                newUser.userSnapshot!.username = username
                newUser.userProfile!.birthday = birthday.convertDateToMediumStyleString()
                newUser.userProfile!.sex = Sex(rawValue: sex)
                
                return self.userBackendService.saveUser(newUser)
            })
            .subscribeNext { (response) in
                self.shouldShowOverlay.value = OverlayAction.Remove
                switch response {
                case .Success:
                    self.signUpComplete.value = true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    private func formatInputs() {
        birthday = inputs.birthday
            .distinctUntilChanged()
            .map({$0.convertDateToMediumStyleString()})
    }

}


