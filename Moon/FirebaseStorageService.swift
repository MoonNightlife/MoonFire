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
    func saveProfilePicture(uid: String, image: UIImage) -> Observable<BackendResponse>
}


struct FirebaseStorageService: PhotoBackendService {
    
    let storageRef = FIRStorage.storage().reference()

    func saveProfilePicture(uid: String, image: UIImage) -> Observable<BackendResponse> {
        
        return Observable.create({ (observer) -> Disposable in
     
            if let thumnailSizeImageData = UIImageJPEGRepresentation(image.resizeImageToThumbnail(), 0.5) {
                if let fullSizeImageData = UIImageJPEGRepresentation(image, 0.5) {
                    
                    self.storageRef.child("profilePictures").child(uid).child("userPic").putData(thumnailSizeImageData, metadata: nil) { (metaData, error) in
                        if let error = error {
                            observer.onNext(BackendResponse.Failure(error: error))
                            observer.onCompleted()
                        } else {
                            self.storageRef.child("profilePictures").child(uid).child("largeProfilePicture").putData(fullSizeImageData, metadata: nil, completion: { (metaData, error) in
                                if let error = error {
                                    observer.onNext(BackendResponse.Failure(error: error))
                                    observer.onCompleted()
                                } else {
                                    observer.onNext(BackendResponse.Success)
                                }
                                observer.onCompleted()
                            })
                        }
                    }
                    
                } else {
                    observer.onNext(BackendResponse.Failure(error: BackendError.ImageDataConversionFailed))
                    observer.onCompleted()
                }
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.ImageDataConversionFailed))
                observer.onCompleted()
            }
        
            return AnonymousDisposable {
                
            }
        
        })
    }
}