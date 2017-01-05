//
//  GoogleService.swift
//  Moon
//
//  Created by Evan Noble on 1/5/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import GoogleSignIn

protocol GoogleLoginProvider {
    func login() -> Observable<LoginResponse>
    func getProviderCredentials() -> ProviderCredentials
}

struct GoogleService: GoogleLoginProvider {
    func login() -> Observable<LoginResponse> {
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        GIDSignIn.sharedInstance().signIn()
        return GIDSignIn.sharedInstance().rx_userDidSignIn
    }
    
    func getProviderCredentials() -> ProviderCredentials {
        let user = GIDSignIn.sharedInstance().currentUser
        let credentials = ProviderCredentials.Google(credentials: GoogleCredentials(accessToken: user.authentication.accessToken, idToken: user.authentication.idToken))
        return credentials
    }
}