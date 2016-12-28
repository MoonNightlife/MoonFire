//
//  FirebaseServiceErrorMessages.swift
//  Moon
//
//  Created by Evan Noble on 12/27/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct FirebaseErrorMessages {
    struct Database {
        static let PasswordEmailError = "To create an account a email and password must be entered"
        static let noAuthData = "No user data was provided after creation of account"
    }
    
    struct Storage {
        static let ThumbnailError = "Couldn't convert thumbnail to data for storage"
        static let ImageError = "Couldn't convert image to data for storage"
    }
}