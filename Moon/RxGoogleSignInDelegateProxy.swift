//
//  RxGoogleSignInDelegateProxy.swift
//  Moon
//
//  Created by Evan Noble on 1/5/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import RxCocoa
import RxSwift
import GoogleSignIn

class RxGoogleSignInDelegateProxy: DelegateProxy, DelegateProxyType, GIDSignInDelegate {
    
    let signInSubject = PublishSubject<LoginResponse>()
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if user != nil {
            signInSubject.on(.Next(LoginResponse.Success))
        } else if let e = error {
            signInSubject.on(.Next(LoginResponse.Failed(error: e)))
        } else {
            signInSubject.onNext(LoginResponse.Failed(error: LoginProviderError.NoUserInfoFromProvider))
        }
        self._forwardToDelegate?.signIn(signIn, didSignInForUser: user, withError: error)
    }
    
    deinit {
        signInSubject.on(.Completed)
    }
    
    static func currentDelegateFor(object: AnyObject) -> AnyObject? {
        let signIn: GIDSignIn = object as! GIDSignIn
        return signIn.delegate
    }
    
    static func setCurrentDelegate(delegate: AnyObject?, toObject object: AnyObject) {
        let signIn: GIDSignIn = object as! GIDSignIn
        signIn.delegate = delegate as! GIDSignInDelegate
    }
    
}

extension GIDSignIn {
    
    var rx_delegate: DelegateProxy {
        return RxGoogleSignInDelegateProxy.proxyForObject(self)
    }
    
    var rx_userDidSignIn: Observable<LoginResponse> {
        let proxy = RxGoogleSignInDelegateProxy.proxyForObject(self)
        return proxy.signInSubject
    }
}
