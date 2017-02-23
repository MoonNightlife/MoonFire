//
//  FirebaseBarService.swift
//  Moon
//
//  Created by Evan Noble on 2/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import ObjectMapper

protocol BarService {
    func getBarInformationFor(BarID barID: String) -> Observable<BackendResult<BarInfo>>
}

struct FirebaseBarService: BarService {
    
    func getBarInformationFor(BarID barID: String) -> Observable<BackendResult<BarInfo>> {
        return Observable.create({ (observer) -> Disposable in
            
            FirebaseRefs.Bars.child(barID).child("barInfo").observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull), let bar = snap.value as? [String:AnyObject] {
                    let context = Context(id: barID)
                    
                    let barObj = Mapper<BarInfo>(context: context).map(bar)
                    
                    if let bar = barObj {
                        observer.onNext(BackendResult.Success(result: bar))
                    } else {
                        observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                    }
                    observer.onCompleted()
                }
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        })
    }
    

    
}