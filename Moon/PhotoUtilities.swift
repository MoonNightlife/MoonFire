//
//  PhotoUtilities.swift
//  Moon
//
//  Created by Evan Noble on 8/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Kingfisher
import GooglePlaces
import Toucan

/**
 Finds the download ref for the city picture, and then downloads it if not in the cache. Lastly, the image is rezized
 - Author: Evan Noble
 - Parameters:
    - cityId: The city's id for the picture that is wanted
    - imageView: The image view that will display the picture
 */
func getCityPictureForCityId(cityId: String, imageView: UIImageView) {
    
    storageRef.child("cityImages").child(cityId).child("cityPic.png").downloadURLWithCompletion { (url, error) in
        if let error = error {
            print(error.description)
        } else if let url = url {
            KingfisherManager.sharedManager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                if let error = error {
                    print(error.description)
                } else if let image = image {
                    let resizedImage = Toucan(image: image).resize(CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
                    imageView.image = resizedImage
                }
            })
        }
    }
}

/**
 Finds the download ref for the user's profile picture, and then downloads it if not in the cache. Lastly, the image is rezized and given a white border
 - Author: Evan Noble
    - Parameters:
    - userId: The user's id for the picture that is wanted
    - imageView: The image view that will display the picture
 */
func getProfilePictureForUserId(userId: String, imageView: UIImageView) {
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    indicator.center = CGPointMake(imageView.frame.size.width / 2, imageView.frame.size.height / 2)
    indicator.startAnimating()
    imageView.addSubview(indicator)
    storageRef.child("profilePictures").child(userId).child("userPic").downloadURLWithCompletion { (url, error) in
        if let error = error {
            indicator.stopAnimating()
            print(error.description)
        } else if let url = url {
            KingfisherManager.sharedManager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                print(cacheType)
                indicator.stopAnimating()
                if let error = error {
                    print(error.description)
                } else if let image = image {
                    let resizedImage = Toucan(image: image).resize(CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
                    let maskImage = Toucan(image: resizedImage).maskWithEllipse(borderWidth: 1, borderColor: UIColor.whiteColor()).image
                    imageView.image = maskImage
                }
            })
        }
    }
}

// MARK: - Google Places Photo Functions
/**
 This functions will find the first photo for the bar id given and set the image to the image view. Once the image is set the activity indicator stops
 - Parameters:
    - placeId: the bar id for the image you want
    - imageView: the image view that the image will be set to
    - indicator: the activity indicator that will stop indicating once the photo is loaded
    - isSpecialsBarPic: if this is set to true then the image will be resized prior to being set to the image view
 */
func loadFirstPhotoForPlace(placeId: String, imageView: UIImageView, isSpecialsBarPic: Bool) {
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
    indicator.center = CGPointMake(imageView.frame.size.width / 2, imageView.frame.size.height / 2)
    indicator.startAnimating()
    imageView.addSubview(indicator)
    imageView.bringSubviewToFront(indicator)
    GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeId) { (photos, error) -> Void in
        if let error = error {
            // TODO: handle the error.
            print("Error: \(error.description)")
        } else {
            if let firstPhoto = photos?.results.first {
                loadImageForMetadata(firstPhoto, imageView: imageView, indicator: indicator, isSpecialsBarPic: isSpecialsBarPic)
            } else {
                indicator.stopAnimating()
                imageView.image = UIImage(named: "Default_Image.png")
            }
        }
    }
}
/**
 This functions is a helper function for "loadFirstPhotoForPlace"
 - Parameters:
    - placeId: the bar id for the image you want
    - imageView: the image view that the image will be set to
    - indicator: the activity indicator that will stop indicating once the photo is loaded
    - isSpecialsBarPic: if this is set to true then the image will be resized prior to being set to the image view
 */
func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, imageView: UIImageView, indicator: UIActivityIndicatorView, isSpecialsBarPic: Bool) {
    GMSPlacesClient.sharedClient()
        .loadPlacePhoto(photoMetadata, constrainedToSize: imageView.bounds.size,
                        scale: imageView.window?.screen.scale ?? 2.0) { (photo, error) -> Void in
                            indicator.stopAnimating()
                            if let error = error {
                                // TODO: handle the error.
                                print("Error: \(error.description)")
                            } else {
                                if isSpecialsBarPic {
                                    imageView.image = resizeImage(photo!, toTheSize: CGSize(width: 50, height: 50))
                                } else {
                                    imageView.image = photo
                                }
                                // TODO: handle attributes here
                                //self.attributionTextView.attributedText = photoMetadata.attributions;
                            }
    }
}

/**
 This is the helper function that is used when rezising the images for the specials view
 - Parameters:
    - image: the image to be resized
    - size: the size the image should be cropped to
 - Returns: The newly resized image
 */
func resizeImage(image:UIImage, toTheSize size:CGSize)->UIImage{
    
    let scale = CGFloat(max(size.width/image.size.width,
        size.height/image.size.height))
    let width:CGFloat  = image.size.width * scale
    let height:CGFloat = image.size.height * scale;
    
    let rr:CGRect = CGRectMake( 0, 0, width, height);
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    image.drawInRect(rr)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    return newImage
}