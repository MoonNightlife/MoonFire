//
//  BackendEnums.swift
//  Moon
//
//  Created by Evan Noble on 12/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

enum BackendResult<Value> {
    case Success(response: Value)
    case Failure(error: NSError)
}

enum BackendResponse {
    case Success
    case Failure(error: NSError)
}

enum ProviderCredentials {
    case Facebook(credentials: FacebookCredentials)
    case Google(credentials: GoogleCredentials)
    case Email(credentials: EmailCredentials)
}

enum ProfilePictureType {
    case Thumbnail
    case FullSize
}

//enum BackendError: String, ErrorType {
//    case InvalidEmail = "To create an account a email and password must be entered"
//    case EmailAlreadyInUse = "The email address you have entered is already in use"
//    case WeakPassword = "The password entered is too weak"
//    case UnknownError = "Uknown error dealing with firebase services"
//    case ThumbnailDataConversionFailure = "Couldn't convert image to thumbnail data for storage"
//    case ImageDataConversionFailure = "Couldn't convert image to data for storage"
//    case NoUserSignedIn = "There currently isn't a user signed in"
//    case UserHasNoUserID = "The user that is trying to be saved doesn't contain a User ID"
//}
//
//// This conversion allows a seperate description string to be used when displaying an alert to the user
//func convertFirebaseErrorToBackendErrorType(error: NSError) -> BackendError {
//    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
//    print(error)
//    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
//    switch error.code {
//    case 17007:
//        return BackendError.EmailAlreadyInUse
//    default:
//        return BackendError.UnknownError
//    }
//    
//}
