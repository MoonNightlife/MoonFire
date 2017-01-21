//
//  ErrorStructs.swift
//  Moon
//
//  Created by Evan Noble on 1/4/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation

// TODO: find a better way to group these errors

struct LoginProviderError {
    static let NoUserInfoFromProvider = NSError(domain: "com.NobleLeyva.Moon", code: 1, userInfo: nil)
    static let UserCancelledProcess = NSError(domain: "com.NobleLeyva.Moon", code: 2, userInfo: nil)
}

struct PhotoUtilitiesError {
    static let URLConversionFailed = NSError(domain: "com.NobleLeyva.Moon", code: 11, userInfo: nil)
    static let NoImageDownloaded = NSError(domain: "com.NobleLeyva.Moon", code: 12, userInfo: nil)
}

struct BackendError {
    static let NoUserSignedIn = NSError(domain: "com.NobleLeyva.Moon", code: 21, userInfo: ["description":"No user signed in"])
    static let ImageDataConversionFailed = NSError(domain: "com.NobleLeyva.Moon", code: 22, userInfo: nil)
    static let CounldNotGetUserInformation = NSError(domain: "com.NobleLeyva.Moon", code: 23, userInfo: ["description":"Cound not construct the user from the backend results"])
    static let NoCityForCityIDProvided = NSError(domain: "com.NobleLeyva.Moon", code: 24, userInfo: ["description":"No city for the city id provided"])
    static let FailedToMapObject = NSError(domain: "com.NobleLeyva.Moon", code: 25, userInfo: ["description":"Could not map object from from json"])
}

struct SMSValidationError {
    static let ValidationError = NSError(domain: "com.NobleLeyva.Moon", code: 31, userInfo: nil)
    static let VerificationError = NSError(domain: "com.NobleLeyva.Moon", code: 32, userInfo: nil)
    static let FomattingError = NSError(domain: "com.NobleLeyva.Moon", code: 33, userInfo: nil)
}