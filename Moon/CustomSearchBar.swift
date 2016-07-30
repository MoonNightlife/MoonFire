//
//  CustomSearchBar.swift
//  Moon
//
//  Created by Evan Noble on 7/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class CustomSearchBar: UISearchBar {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setShowsCancelButton(false, animated: false)
    }
}