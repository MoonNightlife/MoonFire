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