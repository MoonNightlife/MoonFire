//
//  LargePhotoViewController.swift
//  Moon
//
//  Created by Evan Noble on 9/11/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class LargePhotoViewController: UIViewController {
    
    var userId: String? = nil
    @IBOutlet weak var largePhoto: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        // Top View set up
        let header = "Header_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
        getLargeProfilePictureForUserId(userId!, imageView: largePhoto)
        // Do any additional setup after loading the view.
    }
    @IBAction func returnToProfile(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
