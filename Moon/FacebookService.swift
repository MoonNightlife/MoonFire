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


enum LoginResponse {
    case Success
    case Failed(error: NSError)
}

protocol LoginProvider {
    func login() -> Observable<LoginResponse>
    func logout()
    func isUserAlreadyLoggedIn() -> Bool
    func getProviderCredentials() -> ProviderCredentials
    func getBasicProfileForSignedInUser() -> Observable<BackendResult<User2>>
}

struct FacebookService: LoginProvider {
    
    private let loginManager: FBSDKLoginManager!
    
    init() {
        loginManager = FBSDKLoginManager()
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
    
    func getBasicProfileForSignedInUser() -> Observable<BackendResult<User2>> {
        return Observable.create({ (observer) -> Disposable in
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                FBSDKGraphRequest(graphPath: "me", parameters: nil).startWithCompletionHandler({ (connection, result, error) in
                    if error != nil {
                        
                    } else {
                        print(result)
                    }
                })
            } else {
                
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
}