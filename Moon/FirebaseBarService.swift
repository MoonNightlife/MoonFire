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
    func getSpecialsFor(BarID barID: String) -> Observable<BackendResult<[Special2]>>
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
    
    func getSpecialsFor(BarID barID: String) -> Observable<BackendResult<[Special2]>> {
        return getSpecialsInfoFor(barID)
            .flatMap({ (results) -> Observable<BackendResult<[Special2]>> in
                switch results {
                case .Success(let specials):
                    return self.getSpecialLikesForSpecials(specials)
                case .Failure(let error):
                    return Observable.just(BackendResult.Failure(error: error))
                }
            })
    }
    
    // returns an array of the same specials with their 'likes' field populated
    private func getSpecialLikesForSpecials(specials:[Special2]) -> Observable<BackendResult<[Special2]>> {
        return Observable.create({ (observer) -> Disposable in
            //TODO: find a way to wait to return the collection of specials untill all of the likes have been accumulated
            var newSpecials = [Special2]()
            
            for special in specials {
                if let barID = special.barId, let specialID = special.specialId {
                    FirebaseRefs.Bars.child(barID).child("specials").child("specialData").child(specialID).child("likes").observeSingleEventOfType(.Value, withBlock: { (snap) in
                        var likes = [String]()
                        for userID in snap.children {
                            likes.append(userID.key)
                        }
                        let newSpecial = Special2(partialSpecial: special, likes: likes)
                        newSpecials.append(newSpecial)
                        }, withCancelBlock: { (error) in
                            observer.onNext(BackendResult.Failure(error: error))
                            observer.onCompleted()
                    })
                } else {
                    observer.onNext(BackendResult.Failure(error: BackendError.CorruptBarSpecial))
                    observer.onCompleted()
                }
            }
            
            observer.onNext(BackendResult.Success(result: newSpecials))
            observer.onCompleted()
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    private func getSpecialsInfoFor(barID: String) -> Observable<BackendResult<[Special2]>> {
        return Observable.create({ (observer) -> Disposable in
            
            FirebaseRefs.Bars.child(barID).child("specials").child("specialInfo").observeSingleEventOfType(.Value, withBlock: { (snap) in
                var specials = [Special2]()
                for special in snap.children {
                    let special = special as! FIRDataSnapshot
                    if !(special.value is NSNull), let spec = special.value as? [String : AnyObject] {
                        
                        let specialContext = SpecialContext(barID: barID, specialID: special.key)
                        let specObj = Mapper<Special2>(context: specialContext).map(spec)
                        
                        if let specialObj = specObj {
                            if self.seeIfSpecialIsForCurrentDayOfWeek(specialObj) {
                                specials.append(specialObj)
                            }
                        } else {
                            observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                            observer.onCompleted()
                        }
                    }
                }
                print("=================")
                print(barID)
                print(specials)
                print("=================")
                observer.onNext(BackendResult.Success(result: specials))
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