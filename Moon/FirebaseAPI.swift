//
//  FirebaseAPI.swift
//  Moon
//
//  Created by Evan Noble on 6/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

protocol DataProtocol {
    
    // MARK: - User
    func getUserForId(id: String, completionHandler: (user: User?, error: NSError?) -> Void)
    func saveUserForId(id: String, completionHandler: (error: NSError?) -> Void)
    
    // MARK: - Bar
    func getBarForBarId(id: String, completionHandler: (user: User?, error: NSError?) -> Void)
    func saveBarForBarId(id: String, completionHandler: (error: NSError?) -> Void)
}