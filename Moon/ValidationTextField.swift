//
//  ValidationTextField.swift
//  Moon
//
//  Created by Evan Noble on 12/1/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

protocol ValidationTextFieldDelegate: class {
    func presentValidationErrorMessage(String error: String?)
}

class ValidationTextField: UITextField {
    
    var validationErrorMessage: String?
    weak var validationDelegate: ValidationTextFieldDelegate?
    
    var infoButton: UIButton!
    var greenCheck: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customLayout()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        customLayout()
    }
    
    private func customLayout() {
        greenCheck = UIImageView(frame: CGRectMake(0, 0, 15, 15))
        greenCheck.image = UIImage(named: "Accept_Icon")!
        
        
        infoButton = UIButton(frame: CGRectMake(0, 0, 15, 15))
        infoButton.setImage(UIImage(named: "Decline_Icon")!, forState: UIControlState.Normal)
        infoButton.addTarget(self, action: #selector(ValidationTextField.showError(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.clearButtonMode = UITextFieldViewMode.Never
        self.rightViewMode = UITextFieldViewMode.Always
    }
    
    func changeRightViewToGreenCheck(yes: Bool) {
        if yes {
            self.rightView = greenCheck
        } else {
            self.rightView = infoButton
        }
    }
    
    func showError(sender:UIButton) {
        validationDelegate?.presentValidationErrorMessage(String: validationErrorMessage)
    }
    
 
}
