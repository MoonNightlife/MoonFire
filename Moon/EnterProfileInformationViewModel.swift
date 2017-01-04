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
    private let facebookService: LoginProvider!
    private let photoUtlilies: PhotoUtilities!
    
    // Inputs
    let inputs: EnterProfileInformationInputs!
    
    // Output
    var isValidSignupInformtion: Observable<Bool>?
    var doPasswordEntriesMatch: Observable<Bool>?
    
    var firstName = Variable<String>("")
    var isValidFirstName: Observable<Bool>?
    var isValidFirstNameMessage: Observable<String>?
    
    var lastName = Variable<String>("")
    var isValidLastName: Observable<Bool>?
    var isValidLastNameMessage: Observable<String>?

    var isValidUsername: Observable<Bool>?
    var isValidUsernameMessage: Observable<String>?
    
    var gender = Variable<Int>(Sex.None.rawValue)
    var profilePicture = Variable<UIImage?>(nil)
    
    var birthdayString: Observable<String>?
    var signUpComplete = Variable<Bool>(false)
    var signUpCancelled: Observable<Bool>?
    
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    
    
    init(Inputs inputs: EnterProfileInformationInputs, backendService: UserBackendService, validationService: AccountValidation, photoBackendService: PhotoBackendService, facebookService: LoginProvider, photoUtilities: PhotoUtilities) {
        
        self.inputs = inputs
        self.userBackendService = backendService
        self.validationService = validationService
        self.photoBackendService = photoBackendService
        self.facebookService = facebookService
        self.photoUtlilies = photoUtilities
        
        createOutputs()
        subscribeToInputs()
        
        populateFieldsWithProviderInfo()
    }
    
    private func createOutputs() {
        
        let validFirstNameResponse = firstName.asObservable()
            .distinctUntilChanged()
            .map { return self.validationService.isValid(Name: $0) }
        
        isValidFirstName = validFirstNameResponse
            .map({$0.isValid})
        isValidFirstNameMessage = validFirstNameResponse
            .map({$0.Message})
        
        let validLastNameResponse = lastName.asObservable()
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
        
        birthdayString = inputs.birthday
            // Skip the first date sent so the textfield doesn't display a date till user taps
            .skip(1)
            .distinctUntilChanged()
            .map({$0.convertDateToMediumStyleString()})
        
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

    }
    
    private func subscribeToInputs() {
        
        inputs.firstName.asObservable().bindTo(firstName).addDisposableTo(disposeBag)
        inputs.lastName.asObservable().bindTo(lastName).addDisposableTo(disposeBag)
        
        let newUserInformation = Observable.combineLatest(inputs.firstName, inputs.lastName, inputs.username, inputs.birthday.skip(1), inputs.sex) { (firstName, lastName, username, birthday, sex) in
                return (firstName, lastName, username, birthday, sex)
            }
        
        inputs.nextButtonTapped
            .doOnNext({ 
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Saving profile information", type: .Blocking))
            })
            .withLatestFrom(newUserInformation)
            .flatMapFirst({ (firstName, lastName, username, birthday, sex) -> Observable<BackendResponse> in
                
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
    
    // If the user signed up with facebook or google then there may be information we can autofill
    private func populateFieldsWithProviderInfo() {
        if let provider = userBackendService.getUserProvider() {
            switch provider {
            case .Facebook:
                getFacebookInformation()
            case .Google:
                break
            case .Firebase:
                self.profilePicture.value = UIImage(named: "default_pic")
                break
            }
        } else {
            self.errorMessageToDisplay.value = BackendError.NoUserSignedIn.debugDescription
        }
    }
    
    private func getFacebookInformation() {
        facebookService.getBasicProfileForSignedInUser()
            .flatMap({ (results) -> Observable<PhotoResult<UIImage>> in
                switch results {
                case .Success(let userInfo):
                    self.firstName.value = userInfo.firstName ?? ""
                    self.lastName.value = userInfo.lastName ?? ""
                    self.gender.value = userInfo.sex?.rawValue ?? Sex.None.rawValue
                    if let urlString = userInfo.profilePicutreURL {
                        return self.photoUtlilies.getPhotoFor(URL: urlString)
                    } else {
                        return Observable.just(PhotoResult.Failure(error: PhotoUtilitiesError.NoImageDownloaded))
                    }
                case .Failure(let error):
                    return Observable.just(PhotoResult.Failure(error: error))
                }
            })
            .subscribeNext({ (photoResults) in
                switch photoResults {
                case .Success(let photo):
                    self.profilePicture.value = photo
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            })
            .addDisposableTo(disposeBag)
    }


}


