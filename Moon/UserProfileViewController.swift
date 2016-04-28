//
//  UserProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/21/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    var userID: String!
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Monitor the user that was passed to the controller and update view with their information
        rootRef.childByAppendingPath("users").childByAppendingPath(userID).observeEventType(.Value, withBlock: { (snap) in
                print(snap.value["username"]!)
        }) { (error) in
                print(error.description)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        rootRef.childByAppendingPath(userID).removeAllObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
