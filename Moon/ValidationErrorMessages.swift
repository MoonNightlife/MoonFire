//
//  ValidationErrorMessages.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//


struct ValidationErrorMessage {
    struct Name {
        static let NotRightLength = "Name is not right length, must be between \(ValidationConstants.minNameCount) and \(ValidationConstants.maxNameCount) characters."
        static let ContainsNumbersOrSpecialCharacters = "Name can not contain numbers or special characters."
    }
    struct Username {
        static let NotRightLength = "Username is not right length, must be between \(ValidationConstants.minUsernameCount) and \(ValidationConstants.maxUsernameCount) characters."
        static let ContainsWhiteSpaces = "Username can not contain spaces."
        static let ContainsSpecialCharacters = "Username can not contain special or uppercase characters."
    }
    struct Password {
        static let NotRightLength = "Password is not right length, must be greater than \(ValidationConstants.minPasswordCount) characters."
        static let ContainsWhiteSpaces = "Passwords can not contain spaces."
    }
    struct Email {
        static let CorrectFormat = "Email is not in the correct format"
    }
}

struct ValidationConstants {
    static let maxNameCount = 18
    static let minNameCount = 1
    static let maxUsernameCount = 12
    static let minUsernameCount = 5
    static let minPasswordCount = 6
}