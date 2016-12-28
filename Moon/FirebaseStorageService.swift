//
//  FirebaseStorageService.swift
//  Moon
//
//  Created by Evan Noble on 12/27/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import Toucan



//  addedUserToBatch()

protocol PhotoBackendService {
    //func getProfilePicture(uid: String, size: ProfilePictureType) -> Observable<UIImage>
    // This function saves a full size image as well as a thumbnail of the photo
    func saveProfilePicture(uid: String, image: UIImage) -> Observable<Bool>
}

enum FirebaseStorageError: ErrorType {
    case ThumbnailDataConversionError
    case ImageDataConversionError
}

enum ProfilePictureType {
    case Thumbnail
    case FullSize
}

struct FirebaseStorageService: PhotoBackendService {
    
    let storageRef = FIRStorage.storage().reference()

    func saveProfilePicture(uid: String, image: UIImage) -> Observable<Bool> {
        
        return Observable.create({ (observer) -> Disposable in
     
            if let thumnailSizeImageData = UIImageJPEGRepresentation(self.resizeImageToThumbnail(image), 0.5) {
                if let fullSizeImageData = UIImageJPEGRepresentation(image, 0.5) {
                    
                    self.storageRef.child("profilePictures").child(uid).child("userPic").putData(thumnailSizeImageData, metadata: nil) { (metaData, error) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            self.storageRef.child("profilePictures").child(uid).child("largeProfilePicture").putData(fullSizeImageData, metadata: nil, completion: { (metaData, error) in
                                if let error = error {
                                    observer.onError(error)
                                } else {
                                    observer.onNext(true)
                                    observer.onCompleted()
                                }
                            })
                        }
                    }
                    
                } else {
                    observer.onError(FirebaseStorageError.ImageDataConversionError)
                }
            } else {
                observer.onError(FirebaseStorageError.ThumbnailDataConversionError)
            }
        
            return AnonymousDisposable {
                
            }
        
        })
    }
    
    private func resizeImageToThumbnail(image: UIImage) -> UIImage {
        let resizedImage = Toucan(image: image).resize(CGSize(width: 150, height: 150), fitMode: Toucan.Resize.FitMode.Crop).image
        return resizedImage
    }
}