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
    var facebookService: LoginProvider!
    private let userBackendService: UserBackendService!
    
    // Outputs
    var errorMessageToDisplay = Variable<String?>(nil)
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    var loginComplete = Variable<(Bool)>(false)
    var moreUserInfomationNeeded = Variable<(Bool)>(false)
    
    init(inputs: LoginInputs, userService: UserBackendService, facebookService: LoginProvider) {
        self.inputs = inputs
        self.userBackendService = userService
        self.facebookService = facebookService
        
        subscribeToInputs()
    }
    
    func subscribeToInputs() {
        
        inputs.facebookLoginButtonTapped
            .doOnNext({ 
                self.shouldShowOverlay.value = OverlayAction.Show(options: OverlayOptions(message: "Logging in", type: .Blocking))
            })
            .flatMapFirst { (_)  in
                return self.facebookService.login()
            }
            .flatMap({ (facebookResponse) -> Observable<BackendResponse> in
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