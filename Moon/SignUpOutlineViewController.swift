//
//  SignUpOutlineViewController.swift
//  Moon
//
//  Created by Evan Noble on 1/16/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import UIKit

class SignUpOutlineViewController: UIViewController {
    
    var shouldShowAccountCreation = true

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! UITabBarController
            if !shouldShowAccountCreation {
                vc.selectedIndex = 1
            }
        
    }
 

}
