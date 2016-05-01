//
//  ProfileViewController.swift
//  Moon
//
//  Created by Evan Noble on 4/18/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let tapPic = UITapGestureRecognizer()
    
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
        
        //sets a circular profile pic
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height/2
        profilePicture.clipsToBounds = true

        // Adds tap gesture
        tapPic.addTarget(self, action: #selector(ProfileViewController.tappedProfilePic))
        profilePicture.addGestureRecognizer(tapPic)
        profilePicture.userInteractionEnabled = true
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
            
            let base64EncodedString = snap.value["profilePicture"]
            if let imageString = base64EncodedString! {
                let imageData = NSData(base64EncodedString: imageString as! String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let decodedImage = UIImage(data:imageData!)
                self.profilePicture.image = decodedImage
            }
            
            }) { (error) in
                print(error.description)
        }
        
        
    }
    
    // Displays the photo library after the user taps on the profile picture
    func tappedProfilePic(){
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    // Sets the photo in the view and firebase after a photo is selected
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        profilePicture.image = image
        
        // Save image to firebase
        let imageData = UIImageJPEGRepresentation(image,0.1)
        let base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        currentUser.childByAppendingPath("profilePicture").setValue(base64String)
    }

}
