//
//  ValidationErrorMessages.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//


struct ValidationErrorMessage {
    struct Name {
        static var Default = "Name must be between \(ValidationConstants.minNameCount) and \(ValidationConstants.maxNameCount) characters long, and contain no numbers or special characters"
        static let NotRightLength = "Not right length, must be between \(ValidationConstants.minNameCount) and \(ValidationConstants.maxNameCount) characters"
        static let ContainsNumbersOrSpecialCharacters = "Name can not contain numbers or special characters"
    }
    struct Username {
        static let Default = "Username must be between \(ValidationConstants.minUsernameCount) and \(ValidationConstants.maxUsernameCount) characters long, and contain no special characters or spaces"
        static let NotRightLength = "Not right length, must be between \(ValidationConstants.minUsernameCount) and \(ValidationConstants.maxUsernameCount)"
        static let ContainsWhiteSpace = "Username can not contain white spaces"
        static let ContainsSpecialCharacters = "Username can not contain special characters"
    }
}