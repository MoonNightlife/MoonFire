//
//  ErrorStructs.swift
//  Moon
//
//  Created by Evan Noble on 1/4/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation

struct LoginProviderError {
    static let NoUserInfoFromProvider = NSError(domain: "com.NobleLeyva.Moon", code: 5, userInfo: nil)
    static let UserCancelledProcess = NSError(domain: "com.NobleLeyva.Moon", code: 6, userInfo: nil)
}

struct PhotoUtilitiesError {
    static let URLConversionFailed = NSError(domain: "com.NobleLeyva.Moon", code: 3, userInfo: nil)
    static let NoImageDownloaded = NSError(domain: "com.NobleLeyva.Moon", code: 4, userInfo: nil)
}

struct BackendError {
    static let NoUserSignedIn = NSError(domain: "com.NobleLeyva.Moon", code: 1, userInfo: ["description":"No user signed in"])
    static let ImageDataConversionFailed = NSError(domain: "com.NobleLeyva.Moon", code: 2, userInfo: nil)
    static let CounldNotGetUserInformation = NSError(domain: "com.NobleLeyva.Moon", code: 10, userInfo: ["description":"Cound not construct the user from the backend results"])
}

struct SMSValidationError {
    static let ValidationError = NSError(domain: "com.NobleLeyva.Moon", code: 7, userInfo: nil)
    static let VerificationError = NSError(domain: "com.NobleLeyva.Moon", code: 8, userInfo: nil)
    static let FomattingError = NSError(domain: "com.NobleLeyva.Moon", code: 9, userInfo: nil)
}