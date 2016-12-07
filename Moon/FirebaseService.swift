//
//  FirebaseService.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase

protocol BackendService {
    func createAccount()
}


struct FirebaseService: BackendService {
    init() {
        
    }
    
    func createAccount() {
        print("Account Created")
    }
}