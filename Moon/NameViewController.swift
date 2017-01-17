//
//  NameViewController.swift
//  Moon
//
//  Created by Evan Noble on 1/16/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import UIKit

class NameViewController: UIViewController {

    // Outlets
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    // Properties
    private var viewModel: NameViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    private func createAndBindViewModel() {
    
        
    }

}
