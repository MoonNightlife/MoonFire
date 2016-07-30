//
//  CustomSearchController.swift
//  Moon
//
//  Created by Evan Noble on 7/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class CustomSearchController: UISearchController, UISearchBarDelegate {
    
    lazy var _searchBar: CustomSearchBar = {
        [unowned self] in
        let result = CustomSearchBar(frame: CGRectZero)
        result.delegate = self
        
        return result
        }()
    
    override var searchBar: UISearchBar {
        get {
            return _searchBar
        }
    }
}