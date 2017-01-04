//
//  FacebookService.swift
//  Moon
//
//  Created by Evan Noble on 1/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import RxSwift
import ObjectMapper

struct LoginProviderError {
    static let NoUserInfoFromProvider = NSError(domain: "com.NobleLeyva.Moon", code: 5, userInfo: nil)
}

enum LoginResponse {
    case Success
    case Failed(error: NSError)
}

protocol LoginProvider {
    func login() -> Observable<LoginResponse>
    func logout()
    func isUserAlreadyLoggedIn() -> Bool
    func getProviderCredentials() -> ProviderCredentials
    func getBasicProfileForSignedInUser() -> Observable<BackendResult<FacebookUserInfo>>
}

struct FacebookService: LoginProvider {
    
    private let loginManager: FBSDKLoginManager!
    
    init() {
        self.loginManager = FBSDKLoginManager()
    }
    
    func login() -> Observable<LoginResponse> {
        return Observable.create({ (observer) -> Disposable in
            self.loginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: nil, handler: { (result, error) in
                if  error == nil {
                    print(result)
                    observer.onNext(LoginResponse.Success)
                } else {
                    observer.onNext(LoginResponse.Failed(error: error))
                }
                observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func logout() {
        loginManager.logOut()
    }
    
    func isUserAlreadyLoggedIn() -> Bool {
        if FBSDKAccessToken.currentAccessToken() == nil {
            return false
        }
        return true
    }
    
    func getProviderCredentials() -> ProviderCredentials {
        return ProviderCredentials.Facebook(credentials: FacebookCredentials(accessToken: FBSDKAccessToken.currentAccessToken().tokenString))
    }
    
    func getBasicProfileForSignedInUser() -> Observable<BackendResult<FacebookUserInfo>> {
        return Observable.create({ (observer) -> Disposable in
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "first_name, last_name, gender, picture"]).startWithCompletionHandler({ (connection, result, error) in
                    if error != nil {
                        observer.onNext(BackendResult.Failure(error: error))
                    } else {
                        let userInfo = Mapper<FacebookUserInfo>().map(result)
                        if let userInfo = userInfo {
                            observer.onNext(BackendResult.Success(response: userInfo))
                        } else {
                            observer.onNext(BackendResult.Failure(error: LoginProviderError.NoUserInfoFromProvider))
                        }
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
}