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
    case Failure(error: BackendError)
}

enum BackendResponse {
    case Success
    case Failure(error: BackendError)
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
