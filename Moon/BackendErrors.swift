//
//  FirebaseServiceErrorMessages.swift
//  Moon
//
//  Created by Evan Noble on 12/27/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

enum BackendError: String, ErrorType {
    case InvalidEmail = "To create an account a email and password must be entered"
    case EmailAlreadyInUse = "The email address you have entered is already in use"
    case WeakPassword = "The password entered is too weak"
    case UnknownError = "Uknown error dealing with firebase services"
    case ThumbnailDataConversionFailure = "Couldn't convert image to thumbnail data for storage"
    case ImageDataConversionFailure = "Couldn't convert image to data for storage"
}

// This conversion allows a seperate description string to be used when displaying an alert to the user
func convertFirebaseErrorToBackendErrorType(error: NSError) -> BackendError {
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    print(error)
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    switch error.code {
    case 17007:
        return BackendError.EmailAlreadyInUse
    default:
        return BackendError.UnknownError
    }
    
}

