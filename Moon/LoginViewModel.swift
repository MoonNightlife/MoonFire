//
//  LoginViewModel.swift
//  Moon
//
//  Created by Evan Noble on 1/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

class LoginViewModel {
    
    private let inputs: LoginInputs!
    private let disposeBag = DisposeBag()
    
    // Services
    private let facebookService: LoginProvider!
    private let userBackendService: UserBackendService!
    private let pushNotificationService: PushNotificationService!
    
    // Outputs
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    var loginComplete = Variable<(Bool)>(false)
    var moreUserInfomationNeeded = Variable<(Bool)>(false)
    
    init(inputs: LoginInputs, userService: UserBackendService, facebookService: LoginProvider, pushNotificationService: PushNotificationService) {
        
        self.inputs = inputs
        self.userBackendService = userService
        self.facebookService = facebookService
        self.pushNotificationService = pushNotificationService
        
        subscribeToInputs()
    }
    
    func subscribeToInputs() {
        
        inputs.facebookLoginButtonTapped
            .flatMapFirst { (_)  in
                return self.facebookService.login()
            }
            .flatMap({ (facebookResponse) -> Observable<BackendResponse> in
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Logging in", type: .Blocking))
                switch facebookResponse {
                case .Success:
                    return self.userBackendService.signUserIn(self.facebookService.getProviderCredentials())
                case .Failed(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
            .flatMap { (backendResponse) -> Observable<BackendResult<Bool>> in
                switch backendResponse {
                case .Success:
                    return self.userBackendService.doesUserDataAleadyExistForSignedInUser()
                case .Failure(let error):
                    return Observable.just(BackendResult.Failure(error: error))
                }
            }
            .subscribeNext { (backendResponse) in
                self.shouldShowOverlay.value = OverlayAction.Remove
                switch backendResponse {
                case .Success(let exist):
                    if let uid = self.userBackendService.getUidForSignedInUser() {
                        self.pushNotificationService.addUserToNotificationProvider(uid)
                    } else {
                        self.errorMessageToDisplay.value = BackendError.NoUserSignedIn.debugDescription
                    }
                    if exist {
                        self.loginComplete.value = true
                    } else {
                        self.moreUserInfomationNeeded.value = true
                    }
                case .Failure(let error):
                    self.errorMessageToDisplay.value = error.debugDescription
                }
            }
            .addDisposableTo(disposeBag)

        
    }
    
}