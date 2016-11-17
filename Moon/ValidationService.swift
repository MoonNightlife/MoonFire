//
//  ValidationServices.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

typealias ValidationResponse = (isValid: Bool, Message: String?)

struct ValidationConstants {
    static let maxNameCount = 18
    static let minNameCount = 0
    static let maxUsernameCount = 12
    static let minUsernameCount = 5
}

class ValidationService {
    
    // This function makes sure the name entered is valid
    class func isValid(Name name: String) -> ValidationResponse {
        
        var isValid = false
        var message: String? = ValidationErrorMessage.Name.Default
        
        if name.characters.count < ValidationConstants.maxNameCount && name.characters.count > ValidationConstants.minNameCount {
            if !specialCharactersAndNumbersIn(String: name) {
                isValid = true
                message = nil
            } else {
                message = ValidationErrorMessage.Name.ContainsNumbersOrSpecialCharacters
            }
        } else {
            message = ValidationErrorMessage.Name.NotRightLength
        }

        return (isValid, message)
    }
    
    // This functions makes sure the username entered is valid
    class func isValid(Username username: String) -> ValidationResponse {
        
        var isValid = false
        var message: String? = ValidationErrorMessage.Username.Default
        
        if username.characters.count >= ValidationConstants.minUsernameCount && username.characters.count <= ValidationConstants.maxUsernameCount {
            if !checkForWhiteSpaceInString(username) {
                
                if !checkForSpeceialsCharacters(username) {
                    isValid = true
                    message = nil
                } else {
                    message = ValidationErrorMessage.Username.ContainsSpecialCharacters
                }
            } else {
                message = ValidationErrorMessage.Username.ContainsWhiteSpace
            }
        } else {
            message = ValidationErrorMessage.Username.NotRightLength
        }

        return (isValid, message)
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
    private class func speceialsCharactersOrUpperCaseLettersIn(String string: String) -> Bool {
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
}
