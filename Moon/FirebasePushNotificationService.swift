//
//  FirebasePushNotificationService.swift
//  Moon
//
//  Created by Evan Noble on 1/4/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import ObjectMapper

protocol PushNotificationSettingsService {
    func updateFriendsGoingOutNotificaticationSetting(shouldNotify: Bool) -> Observable<BackendResponse>
    func updatePeopleLikingStatusNotificationSetting(shouldNotify: Bool) -> Observable<BackendResponse>
    func getNotificationSettingsForSignedInUser() -> Observable<BackendResult<NotificationSettings>>
}

struct FirebasePushNotificationSettingsService: PushNotificationSettingsService {
    
    private var currentUserRef: FIRDatabaseReference? {
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            let currentUser = rootRef.child("users").child(userID)
            return currentUser
        } else {
            return nil
        }
    }
    
    private var user: FIRUser? {
        return FIRAuth.auth()?.currentUser
    }
    
    
    func updateFriendsGoingOutNotificaticationSetting(shouldNotify: Bool)  -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.NotificationSettings.child(user.uid).child("friendsGoingOut").setValue(shouldNotify, withCompletionBlock: { (error, _) in
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
    
    func updatePeopleLikingStatusNotificationSetting(shouldNotify: Bool)  -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.NotificationSettings.child(user.uid).child("peopleLikingStatus").setValue(shouldNotify, withCompletionBlock: { (error, _) in
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
    
    // If there is no userID then get the settings for the current user
    func getNotificationSettingsForSignedInUser() -> Observable<BackendResult<NotificationSettings>> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                let handle = FirebaseRefs.NotificationSettings.child(user.uid).observeEventType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull), let settings = snap.value as? [String : AnyObject] {
                        
                        let userID = Context(id: snap.key)
                        let mappedNotificationSettings = Mapper<NotificationSettings>(context: userID).map(settings)
                        
                        if let mappedNotificationSettings = mappedNotificationSettings {
                            observer.onNext(BackendResult.Success(response: mappedNotificationSettings))
                        } else {
                            observer.onNext(BackendResult.Failure(error: BackendError.FailedToMapObject))
                        }
                    
                    } else {
                        observer.onNext(.Success(response: NotificationSettings(userID: user.uid)))
                    }
                    
                    observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(.Failure(error: error))
                        observer.onCompleted()
                })
            } else {
                observer.onNext(.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                //TOOD: find a way to remove handle for ref
            }
        })
    }
}