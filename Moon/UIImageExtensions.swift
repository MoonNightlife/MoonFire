//
//  UIImageExtensions.swift
//  Moon
//
//  Created by Evan Noble on 1/21/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import Toucan

extension UIImage {
    func resizeImageToThumbnail() -> UIImage {
        let resizedImage = Toucan(image: self).resize(CGSize(width: 150, height: 150), fitMode: Toucan.Resize.FitMode.Crop).image
        return resizedImage
    }
}
