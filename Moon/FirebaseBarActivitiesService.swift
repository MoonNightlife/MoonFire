//
//  FirebaseBarActivitiesService.swift
//  Moon
//
//  Created by Evan Noble on 2/23/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import ObjectMapper

protocol BarActivitiesService {
    
    func getBarActivityFor(UserType type: UserType) -> Observable<BackendResult<BarActivity2?>>
    func getBarActivitiesForBar(barID: String) -> Observable<BackendResult<[BarActivity2]>>
    
    func createAndSaveBarActivityForSignedInUser(barInfoObservable: Observable<BackendResult<BarInfo>>, userInfoObservable: Observable<BackendResult<UserSnapshot>>) -> Observable<BackendResponse>
    func deleteBarActivityForSignedInUser() -> Observable<BackendResponse>
}

struct FirebaseBarActivitiesService: BarActivitiesService {
    
    private var user: FIRUser? {
        return FIRAuth.auth()?.currentUser
    }
    
    func deleteBarActivityForSignedInUser() -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            if let userID = self.user?.uid {
                FirebaseRefs.BarActivities.child(userID).removeValueWithCompletionBlock({ (error, _) in
                    if let e = error {
                        observer.onNext(BackendResponse.Failure(error: e))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()

                })
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }

        }
    }
    
    func createAndSaveBarActivityForSignedInUser(barInfoObservable: Observable<BackendResult<BarInfo>>, userInfoObservable: Observable<BackendResult<UserSnapshot>>) -> Observable<BackendResponse> {
        
        return self.createBarActivity(barInfoObservable, userInfoObservable: userInfoObservable)
            .flatMap({ (response) -> Observable<BackendResponse> in
                switch response {
                case .Success(let activity):
                    return self.saveBarActivityForSignInUser(activity)
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
        
    }
    
    private func createBarActivity(barInfoObservable: Observable<BackendResult<BarInfo>>, userInfoObservable: Observable<BackendResult<UserSnapshot>>) -> Observable<BackendResult<BarActivity2>> {
        
        return  Observable.combineLatest(barInfoObservable, userInfoObservable) { (barInfo, userInfo) -> BackendResult<BarActivity2> in
            
            var activity: BarActivity2
            
            switch barInfo {
            case .Success(let info):
                activity = BarActivity2(barID: info.barId, barName: info.barName, time: NSDate())
            case .Failure(let error):
                return BackendResult.Failure(error: error)
            }
            
            switch userInfo {
            case .Success(let info):
                let firstName = info.firstName ?? ""
                let lastName = info.lastName ?? ""
                activity.userName = firstName + " " + lastName
                return BackendResult.Success(result: activity)
            case .Failure(let error):
                return BackendResult.Failure(error: error)
            }
        }
        
    }
    
    func getBarActivitiesForBar(barID: String) -> Observable<BackendResult<[BarActivity2]>> {
        return Observable.create { (observer) -> Disposable in
            
           let handle =  FirebaseRefs.BarActivities.queryOrderedByChild("barID").queryEqualToValue(barID).observeEventType(.Value, withBlock: { (snap) in
                
                var activities = [BarActivity2]()
                
                if snap.childrenCount != 0 {
                    // Look at every activity with the barId we are looking at
                    for act in snap.children {
                        let act = act as! FIRDataSnapshot
                        if !(act.value is NSNull),let barAct = act.value as? [String : AnyObject] {
                            let userId = Context(id: act.key)
                            let activity = Mapper<BarActivity2>(context: userId).map(barAct)
                            // If the bar activity is for today then add it to array of activities to be returned
                            if let activity = activity {
                                if self.seeIfShouldDisplayBarActivity(activity) {
                                    activities.append(activity)
                                }
                            } else {
                                observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                            }
                        }
                    }
                }
                observer.onNext(BackendResult.Success(result: activities))

                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
                rootRef.removeObserverWithHandle(handle)
            }
        }
    }
    
    /**
     Check to see if the bar activity should be displayed on the activity feed. The bar activity must have a timestamp for today with a five hour offset
     - Author: Evan Noble
     - Parameters:
     - barRef: The ref to the special
     */
    private func seeIfShouldDisplayBarActivity(barActivity: BarActivity2) -> Bool {
        
        let betweenTwelveAMAndFiveAMNextDay = (barActivity.time?.isGreaterThanDate(NSDate().addHours(19).beginningOfDay()) == true) && (barActivity.time?.isLessThanDate(NSDate().addHours(19).beginningOfDay().addHours(5)) == true)
        let betweenFiveAmAndTwelveAMFirstDay = ((barActivity.time?.isGreaterThanDate(NSDate().addHours(-5).beginningOfDay().addHours(5))) == true) && ((barActivity.time?.isLessThanDate(NSDate().addHours(-5).endOfDay())) == true)
        
        if betweenFiveAmAndTwelveAMFirstDay || betweenTwelveAMAndFiveAMNextDay
        {
            return true
        }
        
        return false
    }

    
    private func saveBarActivityForSignInUser(barActivity: BarActivity2) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let userID = self.user?.uid {
                FirebaseRefs.BarActivities.child(userID).setValue(barActivity.toJSON(), withCompletionBlock: { (error, _) in
                    if let e = error {
                        observer.onNext(BackendResponse.Failure(error: e))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func getBarActivityFor(UserType type: UserType) -> Observable<BackendResult<BarActivity2?>> {
        return Observable.create({ (observer) -> Disposable in
            
            var userID: String!
            
            switch type {
            case .SignedInUser:
                if let user = self.user {
                    userID = user.uid
                } else {
                    observer.onNext(.Failure(error: BackendError.NoUserSignedIn))
                    observer.onCompleted()
                }
            case .OtherUser(let uid):
                userID = uid
            }
            FirebaseRefs.BarActivities.child(userID).observeSingleEventOfType(.Value, withBlock: { (snap) in
                
                if !(snap.value is NSNull),let barAct = snap.value as? [String : AnyObject] {
                    let userId = Context(id: snap.key)
                    let activity = Mapper<BarActivity2>(context: userId).map(barAct)
                    if let activity = activity  {
                        if self.seeIfShouldDisplayBarActivity(activity) {
                            observer.onNext(BackendResult.Success(result: activity))
                        } else {
                            observer.onNext(BackendResult.Success(result: nil))
                        }
                    } else {
                        observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                    }
                } else {
                    observer.onNext(BackendResult.Success(result: nil))
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