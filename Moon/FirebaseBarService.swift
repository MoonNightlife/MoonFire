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
    func getSpecialsFor(BarID barID: String) -> Observable<BackendResult<Special2>>
}

struct FirebaseBarService: BarService {
    
    func getBarInformationFor(BarID barID: String) -> Observable<BackendResult<BarInfo>> {
        return Observable.create({ (observer) -> Disposable in
            
            let handle = FirebaseRefs.Bars.child(barID).child("barInfo").observeEventType(.Value, withBlock: { (snap) in
                if !(snap.value is NSNull), let bar = snap.value as? [String:AnyObject] {
                    let context = Context(id: barID)
                    
                    let barObj = Mapper<BarInfo>(context: context).map(bar)
                    
                    if let bar = barObj {
                        observer.onNext(BackendResult.Success(result: bar))
                    } else {
                        observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                    }
                }
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
                rootRef.removeObserverWithHandle(handle)
            }
        })
    }
    
    func getSpecialsFor(BarID barID: String) -> Observable<BackendResult<Special2>> {
        return Observable.create({ (observer) -> Disposable in
            
            FirebaseRefs.Bars.child(barID).child("specials").child("specialInfo").observeSingleEventOfType(.Value, withBlock: { (snap) in
                
                for special in snap.children {
                    let special = special as! FIRDataSnapshot
                    if !(special.value is NSNull), let spec = special.value as? [String : AnyObject] {
                        
                        let specialContext = SpecialContext(barID: barID, specialID: special.key)
                        let specObj = Mapper<Special2>(context: specialContext).map(spec)
                        
                        if let specialObj = specObj {
                            if self.seeIfSpecialIsForCurrentDayOfWeek(specialObj) {
                                observer.onNext(BackendResult.Success(result: specialObj))
                            }
                        } else {
                            observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                            observer.onCompleted()
                        }
                    }
                }
                observer.onCompleted()
            }) { (error) in
                observer.onNext(BackendResult.Failure(error: error))
                observer.onCompleted()
            }
            

            
            return AnonymousDisposable {
                
            }
        })
        
    }
    
    // Helper methods
    private func seeIfSpecialIsForCurrentDayOfWeek(specialObj: Special2) -> Bool {
        let currentDay = NSDate.getCurrentDay()
        
        let isDayOfWeek = currentDay == specialObj.dayOfWeek
        let isWeekDaySpecial = specialObj.dayOfWeek == Day.Weekdays
        let isNotWeekend = (currentDay != Day.Sunday) && (currentDay != Day.Saturday)
        if isDayOfWeek || (isWeekDaySpecial && isNotWeekend) {
            return true
        } else {
            return false
        }
        
    }
    
    

    
}