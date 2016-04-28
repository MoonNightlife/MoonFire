//
//  ProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/18/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var age: UILabel!
    @IBOutlet weak var gender: UILabel!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.title = "Profile"
        
        // Finds the current users information and populates the view
        currentUser.observeSingleEventOfType(.Value, withBlock: { (snap) in
            self.username.text = snap.value["username"] as? String
            self.name.text = snap.value["name"] as? String
            self.email.text = snap.value["email"] as? String
            self.age.text = snap.value["age"] as? String
            self.gender.text = snap.value["gender"] as? String
            }) { (error) in
                print(error.description)
        }
    }

}
