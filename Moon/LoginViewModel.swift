//
//  LoginViewModel.swift
//  Moon
//
//  Created by Evan Noble on 1/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift


enum PostLoginAction {
    case MoreInformationNeeded
    case LoginComplete
    case Failed(error: NSError)
}

class LoginViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Services
    private let facebookService: FacebookLoginProvider!
    private let userBackendService: UserBackendService!
    private let pushNotificationService: PushNotificationService!
    private let googleService: GoogleLoginProvider!
    
    // Inputs
    var email = PublishSubject<String>()
    var password = PublishSubject<String>()
    var loginButtonTapped = PublishSubject<Void>()
    var facebookLoginButtonTapped = PublishSubject<Void>()
    var forgotPasswordButtonTapped = PublishSubject<Void>()
    var googleSignInButtonTapped = PublishSubject<Void>()
    
    // Outputs
    var shouldShowOverlay = Variable<(OverlayAction)>(.Remove)
    var postLoginAction: Observable<PostLoginAction>!
    
    init(userService: UserBackendService, facebookService: FacebookLoginProvider, pushNotificationService: PushNotificationService, googleService: GoogleLoginProvider) {
        
        self.userBackendService = userService
        self.facebookService = facebookService
        self.pushNotificationService = pushNotificationService
        self.googleService = googleService
        
        createOutputs()
    }
    
    func createOutputs() {
        
        // Google login
        let googleLoginFinished = googleSignInButtonTapped
            .flatMapFirst { (_) -> Observable<LoginResponse> in
                return self.googleService.login()
            }
            .flatMap({ (result) -> Observable<PostLoginAction> in
                switch result {
                    case .Success:
                        return self.logUserIn(self.googleService.getProviderCredentials())
                    case .Failed(let error):
                        return Observable.just(PostLoginAction.Failed(error: error))
                    }
            })
        
        // Email Login
        let emailCredentials = Observable.combineLatest(email, password) { (email, password)  in
            return ProviderCredentials.Email(credentials:  EmailCredentials(email: email, password: password))
        }
        
        let emailLoginFinished = loginButtonTapped
            .withLatestFrom(emailCredentials)
            .flatMapFirst({ emailCredentials -> Observable<PostLoginAction> in
                return self.logUserIn(emailCredentials)
            })
        
        // Facebook login
        let facebookLoginFinished = facebookLoginButtonTapped
            .flatMapFirst({ (_) -> Observable<LoginResponse> in
                if self.facebookService.isUserAlreadyLoggedIn() {
                    return Observable.just(LoginResponse.Success)
                } else {
                    return self.facebookService.login()
                }
            })
            .flatMap({ (fbLoginResponse) -> Observable<PostLoginAction> in
                switch fbLoginResponse {
                case .Success:
                    return self.logUserIn(self.facebookService.getProviderCredentials())
                case .Failed(let error):
                    return Observable.just(PostLoginAction.Failed(error: error))
                }
            })
        
        postLoginAction = Observable.of(googleLoginFinished, emailLoginFinished, facebookLoginFinished).merge()
        
    }
    
    // Helper method to log user into firebase based on provider
    private func logUserIn(provider: ProviderCredentials) -> Observable<PostLoginAction> {
        
        return self.userBackendService.signUserIn(provider)
                .flatMap { (backendResponse) -> Observable<BackendResult<Bool>> in
                    switch backendResponse {
                    case .Success:
                        return self.userBackendService.doesUserDataAleadyExistForSignedInUser()
                    case .Failure(let error):
                        return Observable.just(BackendResult.Failure(error: error))
                    }
                }
                .map { (backendResponse) in
                    self.shouldShowOverlay.value = OverlayAction.Remove
                    switch backendResponse {
                    case .Success(let exist):
                        self.pushNotificationService.addUserToNotificationProvider(self.userBackendService.getUidForSignedInUser()!)
                        if exist {
                            return PostLoginAction.LoginComplete
                        } else {
                            return PostLoginAction.MoreInformationNeeded
                        }
                    case .Failure(let error):
                        return PostLoginAction.Failed(error: error)
                    }
                }
    }
    
}