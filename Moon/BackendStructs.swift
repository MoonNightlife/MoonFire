//
//  BackendStructs.swift
//  Moon
//
//  Created by Evan Noble on 12/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct GoogleCredentials {
    let accessToken: String
    let IDToken: String
}

struct EmailCredentials {
    let email: String
    let password: String
}

struct FacebookCredentials {
    let accessToken: String
}

struct BackendError {
    static let NoUserSignedIn = NSError(domain: "com.NobleLeyva.Moon", code: 1, userInfo: nil)
    static let ImageDataConversionFailed = NSError(domain: "com.NobleLeyva.Moon", code: 2, userInfo: nil)
}