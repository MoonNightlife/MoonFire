//
//  UserSearchResultTableViewCell.swift
//  Moon
//
//  Created by Evan Noble on 2/7/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class UserSearchResultTableViewCell: UITableViewCell {
    
    var userIDForUser: String!
    var viewModel = UserSearchResultCellViewModel(userService: FirebaseUserService(), photoService: FirebasePhotoService(), photoUtilities: KingFisherUtilities())
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UILabel!
    @IBOutlet weak var nameTextField: UILabel!
    
    // Theme colors
    let customGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
    let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        usernameTextField.textColor = customGray
        nameTextField.textColor = customBlue
        self.backgroundColor = UIColor.clearColor()
    }
    
    func bindViewModel() {
        // V to VM
        viewModel.userID.value = userIDForUser
        
        // VM to V
        viewModel.username?.bindTo(usernameTextField.rx_text).addDisposableTo(disposeBag)
        viewModel.name?.bindTo(nameTextField.rx_text).addDisposableTo(disposeBag)
        viewModel.profilePicture?.bindTo(profileImageView.rx_image).addDisposableTo(disposeBag)
        
    }

}
