//
//  LogInViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import SwiftOverlays
import HTYTextField

class LogInViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var emailText: HTYTextField!
    @IBOutlet weak var password: HTYTextField!
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        emailText.rightPlaceholder = "xxx@xxx.xx"
        password.rightPlaceholder = "6-12 Characters"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    
        if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil && currentUser.authData != nil {
            self.performSegueWithIdentifier("LoggedIn", sender: nil)
        }
    }
    
    // MARK: - User Login and Logout Actions
    @IBAction func logUserIn(sender: UIButton) {
        let email = self.emailText.text
        let password = self.password.text
        
        
        if email != "" && password != "" {
           SwiftOverlays.showBlockingWaitOverlayWithText("Logging In")
            rootRef.authUser(email, password: password, withCompletionBlock: { (error, authData) -> Void in
                if error == nil {
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                    print("Logged In")
                    self.performSegueWithIdentifier("LoggedIn", sender: nil)
                } else {
                    print(error)
                }
                SwiftOverlays.removeAllBlockingOverlays()
            })
        } else {
            let alert = UIAlertController(title: "Error", message: "Enter email and password", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
