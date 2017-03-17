//
//  SpecialTableViewCell.swift
//  Moon
//
//  Created by Evan Noble on 2/11/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import UIKit

class SpecialTableViewCell: UITableViewCell {
    
    let heartButton = SpecialButton()
    let likeLable = UILabel()
    var cellSpecial: Special2! {
        didSet {
            populateCellWithSpecial()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //custom color set up
        let customGray = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        let customBlue = UIColor(red: 31/255, green: 92/255, blue: 167/255, alpha: 1)
        
        //heart button set up
        let image = UIImage(named: "Heart_Icon2")?.imageWithRenderingMode(.AlwaysTemplate)
        heartButton.imageView?.tintColor = UIColor.grayColor()
        heartButton.setImage(image!, forState: UIControlState.Normal)
        heartButton.addTarget(self, action: #selector(BarSearchViewController.likeTheSpecial(_:)), forControlEvents: .TouchUpInside)
        heartButton.frame = CGRectMake(80, 55, 18, 18)
        self.contentView.addSubview(heartButton)
        
        //like label set up
        likeLable.frame = CGRectMake(100, 55, 120, 18)
        likeLable.font = UIFont(name: "Roboto-Bold", size: 10)
        likeLable.textColor = customBlue
        likeLable.tag = 2
        self.contentView.addSubview(likeLable)
        
        //Bar Image set up
        let barImage = UIImage(named: "translucent_bar_view.png")
        let newImage = resizeImage(barImage!, toTheSize: CGSizeMake(50, 50))
        self.imageView!.image = newImage
        self.imageView!.layer.cornerRadius = 50 / 2
        self.imageView!.layer.masksToBounds = false
        self.imageView!.clipsToBounds = true
        
        // cell.imageView?.image = cellImage
        self.textLabel?.textColor = customBlue
        self.detailTextLabel?.textColor = customGray
        self.textLabel?.font = UIFont(name: "Roboto-Bold", size: 16)
        self.detailTextLabel?.font = UIFont(name: "Roboto-Bold", size: 12)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func populateCellWithSpecial() {
        //TODO: call method to get image for cell
        //self.imageView?.image = special.barId!
        self.textLabel?.text = cellSpecial.description
        self.detailTextLabel?.text = cellSpecial.barName
        likeLable.text = String(cellSpecial.likes?.count ?? 0)
    }

}
