//
//  BarActivityTableViewCell.swift
//  Moon
//
//  Created by Evan Noble on 5/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit

class BarActivityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var user: UIButton!
    @IBOutlet weak var bar: UIButton!
    @IBOutlet weak var Time: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numLikeButton: UIButton!

    // Cell delegate
    var delegate: BarActivityCellDelegate?
    var activityId: String?
    var index: Int?
    var timeStamp: NSTimeInterval?

    @IBAction func nameButtonTapped(sender: UIButton) {
        if let index = index {
            delegate?.nameButtonTapped(index)
        }
    }
    
    @IBAction func barButtonTapped(sender: UIButton) {
        if let index = index {
            delegate?.barButtonTapped(index)
        }
    }
    
    @IBAction func numLikeButtonTapped(sender: UIButton) {
        if let timeStamp = timeStamp, let activityId = activityId {
            delegate?.numButtonTapped(activityId, timeStamp: timeStamp)
        }
    }
    
    @IBAction func heartButtonTapped(sender: UIButton) {
        if let activityId = activityId, let index = index {
            delegate?.likeButtonTapped(activityId, index: index)
        }
    }
    
}
