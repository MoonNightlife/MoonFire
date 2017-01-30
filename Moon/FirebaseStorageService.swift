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
    func saveProfilePicture(uid: String, image: UIImage) -> Observable<BackendResponse>
    func deleteProfilePictureForUser(uid: String) -> Observable<BackendResponse>
    func getProfilePictureUrlFor(UserID userID: String, type: ProfilePictureType) -> Observable<BackendResult<NSURL>>
}


struct FirebaseStorageService: PhotoBackendService {
    
    let storageRef = FIRStorage.storage().reference()
    
    /**
     Finds the download ref for the user's profile picture, and then downloads it if not in the cache. Lastly, the image is rezized based on imageview passed in and given a white border
     - Author: Evan Noble
     - Parameters:
     - userId: The user's id for the picture that is wanted
     - imageView: The image view that will display the picture
     */
    func getProfilePictureUrlFor(UserID userID: String, type: ProfilePictureType) -> Observable<BackendResult<NSURL>> {
        return Observable.create({ (observer) -> Disposable in
            
//            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
//            indicator.center = CGPointMake(imageView.frame.size.width / 2, imageView.frame.size.height / 2)
//            indicator.startAnimating()
//            imageView.addSubview(indicator)
            let pictureTypeRef: String!
            switch type {
            case .FullSize:
                pictureTypeRef = "largeProfilePicture"
            case .Thumbnail:
                pictureTypeRef = "userPic"
            }
            
            self.storageRef.child("profilePictures").child(userID).child(pictureTypeRef).downloadURLWithCompletion { (url, error) in
                if let error = error {
                    //indicator.stopAnimating()
                    observer.onNext(BackendResult.Failure(error: error))
                } else if let url = url {
                    observer.onNext(BackendResult.Success(response: url))
                } else {
                    observer.onNext(BackendResult.Failure(error: PhotoUtilitiesError.UnknownErrorWhenRetrievingImage))
                }
                
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
        
        
        
        

    }
    
    func deleteProfilePictureForUser(uid: String) -> Observable<BackendResponse> {
        return Observable.combineLatest(deleteFullSizeProfilePic(uid), deleteProfilePicThumnailForUser(uid), resultSelector: {
            
            var e: NSError?
            
            switch $0 {
            case .Success:
                break
            case .Failure(let error):
                e = error
            }
            
            switch $1 {
            case .Success:
                break
            case .Failure(let error):
                e = error
            }
            
            if let e = e {
                return .Failure(error: e)
            } else {
                return BackendResponse.Success
            }
        })
    }
    
    private func deleteProfilePicThumnailForUser(uid: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            self.storageRef.child("profilePictures").child(uid).child("userPic").deleteWithCompletion { (error) -> Void in
                if let error = error {
                    observer.onNext(BackendResponse.Failure(error: error))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    private func deleteFullSizeProfilePic(uid: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            self.storageRef.child("profilePictures").child(uid).child("largeProfilePicture").deleteWithCompletion { (error) -> Void in
                if let error = error {
                    observer.onNext(BackendResponse.Failure(error: error))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }

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