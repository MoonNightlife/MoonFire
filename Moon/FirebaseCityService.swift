//
//  FirebaseCityService.swift
//  Moon
//
//  Created by Evan Noble on 1/21/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper
import RxSwift
import Firebase

protocol CityService {
    func getCities() -> Observable<BackendResult<[City2]>>
    func getCityFor(cityID: String) -> Observable<BackendResult<City2>>
}

struct FirebaseCityService: CityService {
    
    func getCityFor(cityID: String) -> Observable<BackendResult<City2>> {
        return Observable.create({ (observer) -> Disposable in
            
            FirebaseRefs.Cities.child(cityID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                
                
                
                if !(snap.value is NSNull), let cityInformation = snap.value as? [String : AnyObject] {
                    
                    let cityId = Context(id: snap.key)
                    let mappedCityObject = Mapper<City2>(context: cityId).map(cityInformation)
                    if let mappedCityObject = mappedCityObject {
                        observer.onNext(BackendResult.Success(result: mappedCityObject))
                    } else {
                        observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                    }
                    
                } else {
                    observer.onNext(BackendResult.Failure(error: BackendError.NoCityForCityIDProvided))
                }
                
                observer.onCompleted()
                
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func getCities() -> Observable<BackendResult<[City2]>> {
        return Observable.create({ (observer) -> Disposable in
            var collectionOfCities = [City2]()
            FirebaseRefs.Cities.observeSingleEventOfType(.Value, withBlock: { (cities) in
                
                for city in cities.children {
                    let citySnap = city as! FIRDataSnapshot
                    if !(citySnap.value is NSNull), let cityInformation = citySnap.value as? [String : AnyObject] {
                        
                        let cityId = Context(id: citySnap.key)
                        let mappedCityObject = Mapper<City2>(context: cityId).map(cityInformation)
                        if let mappedCityObject = mappedCityObject {
                            collectionOfCities.append(mappedCityObject)
                        }
                    }
                }
                
                observer.onNext(BackendResult.Success(result: collectionOfCities))
                observer.onCompleted()
                
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        })
    }
}