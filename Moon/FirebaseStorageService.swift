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
    func deleteProfilePictureForUser(uid: String) -> Observable<BackendResponse>
}


struct FirebaseStorageService: PhotoBackendService {
    
    let storageRef = FIRStorage.storage().reference()
    
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