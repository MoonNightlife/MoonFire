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

struct EnterProfileInformationInputs {
    let firstName: ControlProperty<String>
    let lastName: ControlProperty<String>
    let username: ControlProperty<String>
    let birthday: ControlProperty<NSDate>
    let nextButtonTapped: ControlEvent<Void>
    let sex: ControlProperty<Int>
}


class EnterProfileInformationViewModel {
    
    // This is needed to conform to the SegueHandlerType protocol
    enum SegueIdentifier: String {
        case EnterPhoneNumber
    }
    
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
        
        inputs.nextButtonTapped
            .doOnNext({ 
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Saving profile information", type: .Blocking))
            })
            .withLatestFrom(newUserInformation)
            .flatMapFirst({ (firstName, lastName, username, birthday, sex) -> Observable<BackendResponse> in
                
                var newUser: User2 = User2()
                newUser.firstName = firstName
                newUser.lastName = lastName
                newUser.username = username
                newUser.birthday = birthday.convertDateToMediumStyleString()
                newUser.sex = Sex(rawValue: sex)
                
                return self.userBackendService.saveUser(newUser)
            })
            .subscribeNext { (response) in
                self.shouldShowOverlay.value = OverlayAction.Remove
                switch response {
                case .Success:
                    self.signUpComplete.value = true
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.rawValue
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    private func formatInputs() {
        birthday = inputs.birthday
            .distinctUntilChanged()
            .map({$0.convertDateToMediumStyleString()})
    }
    
//    private func createAccount() {
//        if let email = newUser.email, let password = newUser.password {
//            
//            let credentials = ProviderCredentials.Email(credentials: EmailCredentials(email: email, password: password))
//            return userBackendService.createAccount(credentials)
//                        .flatMapLatest({ (response) -> Observable<BackendResponse> in
//                            switch response {
//                            case .Success(let uid):
//                                self.newUser.userId = uid
//                                // Need to remove this once the rest of the app is refactored, we are no longer storing the uid in NSUserDefault
//                                NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
//                                return self.photoBackendService.saveProfilePicture(uid, image: UIImage(named: "default_pic.png")!)
//                            case .Failure(let error):
//                                self.shouldShowOverlay.value = OverlayAction.Remove
//                                self.errorMessageToDisplay.value = error.rawValue
//                                return self.userBackendService.deleteAccountForSignedInUser()
//                            }
//                        })
//                        .subscribeNext({ (response) in
//                            self.shouldShowOverlay.value = OverlayAction.Remove
//                            switch response {
//                            case .Failure(let error):
//                                self.userBackendService.deleteAccountForSignedInUser()
//                                self.errorMessageToDisplay.value = error.rawValue
//                            case .Success:
//                                self.userBackendService.saveUser(user)
//                                self.signUpComplete.value = true
//                            }
//                        })
//                    .addDisposableTo(disposeBag)
//            }
//        }

}


