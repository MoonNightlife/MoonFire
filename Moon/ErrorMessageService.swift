//
//  ErrorMessageService.swift
//  Moon
//
//  Created by Evan Noble on 12/6/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SCLAlertView


struct ErrorOptions {
    var alertViewOptions: SCLAlertView.SCLAppearance
    var errorTitle: String
    var errorMessage: String
    
    init(errorTitle: String = "Error", errorMessage: String = "Unknown Error", alertViewOptions: SCLAlertView.SCLAppearance = K.Apperances.NormalApperance) {
        
        self.errorTitle = errorTitle
        self.errorMessage = errorMessage
        self.alertViewOptions = alertViewOptions
    }
}

protocol ErrorPopoverRenderer {
    func presentError(alertOptions: ErrorOptions)
}

extension ErrorPopoverRenderer where Self: UIViewController {
    func presentError(alertOptions: ErrorOptions) {
        SCLAlertView(appearance: alertOptions.alertViewOptions).showNotice(alertOptions.errorTitle, subTitle: alertOptions.errorMessage)
    }
}