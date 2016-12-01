//
//  ValidationServices.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

protocol AccountValidation {
    static func isValid(Name name: String) -> ValidationResponse
    static func isValid(Username username: String) -> ValidationResponse
    static func isValid(Password password: String) -> ValidationResponse
    static func isValid(Email email: String) -> ValidationResponse
}

typealias ValidationResponse = (isValid: Bool, Message: String)

class ValidationService: AccountValidation {
    
    static func isValid(Name name: String) -> ValidationResponse {
        
        let isValidLength = (name.characters.count < ValidationConstants.maxNameCount) && (name.characters.count >= ValidationConstants.minNameCount)
        let containsSpecialCharsAndNums = specialCharactersAndNumbersIn(String: name)
        
        var message = ""
        
        if !isValidLength  {
            // Adds space to end of string incase next error message is attached to returned error string
            message += ValidationErrorMessage.Name.NotRightLength + " "
        }
        
        if containsSpecialCharsAndNums {
            message += ValidationErrorMessage.Name.ContainsNumbersOrSpecialCharacters
        }
        
        let isValid = isValidLength && !containsSpecialCharsAndNums ? true : false

        return (isValid, message)
    }
    
    static func isValid(Username username: String) -> ValidationResponse {
        
        let isValidLength = (username.characters.count >= ValidationConstants.minUsernameCount) && (username.characters.count <= ValidationConstants.maxUsernameCount)
        let containsSpaces = whiteSpacesIn(String: username)
        let containsSpecialAndUppercaseChars = speceialsCharactersAndUpperCaseLettersIn(String: username)
        
        var message = ""
        
        if !isValidLength {
            // Adds space to end of string incase next error message is attached to returned error string
            message += ValidationErrorMessage.Username.NotRightLength + " "
        }
        
        if containsSpaces {
            // Adds space to end of string incase next error message is attached to returned error string
            message += ValidationErrorMessage.Username.ContainsWhiteSpaces + " "
        }
        
        if containsSpecialAndUppercaseChars {
            message += ValidationErrorMessage.Username.ContainsSpecialCharacters
        }
        
        let isValid = isValidLength && !containsSpaces && !containsSpecialAndUppercaseChars ? true : false

        return (isValid, message)
    }
    
    static func isValid(Password password: String) -> ValidationResponse {
        
        let isValidLength = (password.characters.count >= ValidationConstants.minPasswordCount)
        let containsSpaces = whiteSpacesIn(String: password)
        
        var message = ""
        
        if !isValidLength {
            // Adds space to end of string incase next error message is attached to returned error string
            message += ValidationErrorMessage.Password.NotRightLength + " "
        }
        
        if containsSpaces {
            message += ValidationErrorMessage.Password.ContainsWhiteSpaces
        }
        
        let isValid = isValidLength && !containsSpaces ? true : false
        
        return (isValid, message)
        
    }
    
    static func isValid(Email email: String) -> ValidationResponse {
        
        let correctFormat = correctEmailFormat(email)
        
        var message = ""
        
        if !correctFormat {
            message += ValidationErrorMessage.Email.CorrectFormat
        }
        
        let isValid = correctFormat ? true : false
        
        return (isValid,message)
    }
    
}

private typealias PrivateHelperFunctions = ValidationService
extension PrivateHelperFunctions {
    
    // The function returns true if there are numbers or special characters
    private class func specialCharactersAndNumbersIn(String string: String) -> Bool {
        
        let characterset = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ ")
        if string.rangeOfCharacterFromSet(characterset.invertedSet) != nil {
            return true
        } else {
            return false
        }
    }
    
    // This function checks for special characters and uppercase letters and will return true if any are found
    private class func speceialsCharactersAndUpperCaseLettersIn(String string: String) -> Bool {
        let characterset = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyz0123456789")
        if string.rangeOfCharacterFromSet(characterset.invertedSet) != nil {
            return true
        } else {
            return false
        }
    }
    
    // This function returns true if there are white spaces in the string
    private class func whiteSpacesIn(String string: String) -> Bool {
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        
        let range = string.rangeOfCharacterFromSet(whitespace)
        
        // Range will be nil if no whitespace is found
        if range != nil {
            return true
        } else {
            return false
        }
    }
    
    // Function returns true if email is in right format
    private class func correctEmailFormat(email:String) -> Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(email)
    }
}
