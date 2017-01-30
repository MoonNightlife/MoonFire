//
//  PhotoServices.swift
//  Moon
//
//  Created by Evan Noble on 1/3/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import Kingfisher
import RxSwift

enum PhotoResult<Value> {
    case Success(result: Value)
    case Failure(error: NSError)
}



protocol PhotoUtilities {
    func getPhotoFor(URL url: String) -> Observable<PhotoResult<UIImage>>
}

//KingfisherManager.sharedManager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
//    //indicator.stopAnimating()
//    if let error = error {
//        observer.onNext(BackendResult.Failure(error: error))
//    } else if let image = image {
//        let resizedImage = Toucan(image: image).resize(CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image
//        let maskImage = Toucan(image: resizedImage).maskWithEllipse(borderWidth: 1, borderColor: UIColor.whiteColor()).image
//        observer.onNext(BackendResult.Success(response: maskImage))
//    } else {
//        observer.onNext(BackendResult.Failure(error: PhotoUtilitiesError.UnknownErrorWhenRetrievingImage))
//    }
//    
//    observer.onCompleted()
//})





struct KingFisherUtilities: PhotoUtilities {
    
    func getPhotoFor(URL url: String) -> Observable<PhotoResult<UIImage>> {
        return Observable.create({ (observer) -> Disposable in
            if let url = NSURL(string: url) {
                KingfisherManager.sharedManager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let error = error {
                        observer.onNext(PhotoResult.Failure(error: error))
                    } else if let image = image {
                        observer.onNext(PhotoResult.Success(result: image))
                    } else {
                        observer.onNext(PhotoResult.Failure(error: PhotoUtilitiesError.NoImageDownloaded))
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext(PhotoResult.Failure(error: PhotoUtilitiesError.URLConversionFailed))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
}