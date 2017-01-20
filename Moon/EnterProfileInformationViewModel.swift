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
    private let userBackendService: UserAccountBackendService!
    private let validationService: AccountValidation!
    private let photoBackendService: PhotoBackendService!
    private let facebookService: FacebookLoginProvider!
    private let photoUtlilies: PhotoUtilities!
    
    // Inputs
    let firstNameInput = BehaviorSubject<String>(value: "")
    let lastNameInput = BehaviorSubject<String>(value: "")
    let username = BehaviorSubject<String>(value: "")
    let birthday = PublishSubject<NSDate>()
    let nextButtonTapped = PublishSubject<Void>()
    let cancelledButtonTapped = PublishSubject<Void>()
    let sex = PublishSubject<Sex>()
    
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
    
    
    init(backendService: UserAccountBackendService, validationService: AccountValidation, photoBackendService: PhotoBackendService, facebookService: FacebookLoginProvider, photoUtilities: PhotoUtilities) {
        
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
        
        let validUsernameResponse = username
            .map { self.validationService.isValid(Username: $0) }
        
        let userNameFree = username
            .distinctUntilChanged()
            .flatMapLatest { (username) -> Observable<BackendResult<Bool>> in
                return self.userBackendService.isUsernameFree(username)
            }
        let freeAndValidUsername: Observable<Bool> = Observable.combineLatest(validUsernameResponse, userNameFree, resultSelector: {
            switch $1 {
            case .Success(let response):
                return (response && $0.isValid)
            case .Failure(let error):
                self.errorMessageToDisplay.value = error.debugDescription
                return false
            }
        })

        isValidUsername = freeAndValidUsername
        isValidUsernameMessage = validUsernameResponse
            .map({$0.Message})
        
        isValidSignupInformtion = Observable
            .combineLatest(validFirstNameResponse, validLastNameResponse, freeAndValidUsername) {
                return $0.0 && $1.0 && $2
        }
        
        birthdayString = birthday
            .map({$0.convertDateToMediumStyleString()})
        
        signUpCancelled = cancelledButtonTapped
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
        
        firstNameInput.asObservable().bindTo(firstName).addDisposableTo(disposeBag)
        lastNameInput.asObservable().bindTo(lastName).addDisposableTo(disposeBag)
        
        let newUserInformation = Observable.combineLatest(firstName.asObservable(), lastName.asObservable(), username, birthday, sex) { (firstName, lastName, username, birthday, sex) in
                return (firstName, lastName, username, birthday, sex)
            }
        
        nextButtonTapped
            .doOnNext({ 
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Saving Profile Information", type: .Blocking))
            })
            .withLatestFrom(newUserInformation)
            .flatMapFirst({ (firstName, lastName, username, birthday, sex) -> Observable<BackendResponse> in
                
                var newUser: User2 = User2(userSnapshot: UserSnapshot(), userProfile: UserProfile())
                newUser.userSnapshot!.firstName = firstName
                newUser.userSnapshot!.lastName = lastName
                newUser.userSnapshot!.username = username
                newUser.userProfile!.birthday = birthday.convertDateToMediumStyleString()

                newUser.userProfile!.sex = sex
                
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


