//
//  NameViewModel.swift
//  Moon
//
//  Created by Evan Noble on 1/16/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

struct NameViewModel {
    
    // Inputs
    var firstName = BehaviorSubject<String>(value: "")
    var lastName = BehaviorSubject<String>(value:"")
    var saveName = PublishSubject<Void>()
    
    //Outputs
    
    // Properties
    private let userBackendService: UserBackendService
    
    init(userBackendService: UserBackendService) {
        self.userBackendService = userBackendService
    }
    
}