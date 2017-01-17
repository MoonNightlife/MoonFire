//
//  FirebaseUserService.swift
//  Moon
//
//  Created by Evan Noble on 1/16/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

protocol UserBackendService {
    func updateName(firstName: String, lastName: String) -> Observable<BackendResponse>
    func updatePrivacy(isOn: Bool) -> Observable<BackendResponse>
}

struct FirebaseUserService: UserBackendService {
    
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
    
    func updateName(firstName: String, lastName: String) -> Observable<BackendResponse> {
        return updateFirstName(firstName)
            .flatMap({ (response) -> Observable<BackendResponse> in
                switch response {
                case .Success:
                    return self.updateLastName(lastName)
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
    }
    
    func updatePrivacy(isOn: Bool) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let ref = self.currentUserRef {
                ref.child("snapShot").updateChildValues(["privacy": isOn])
                observer.onNext(BackendResponse.Success)
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
            }
            return AnonymousDisposable {
                
            }
        })
    }
    
    private func updateFirstName(firstName: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let ref = self.currentUserRef {
                ref.child("snapShot").child("firstName").setValue(firstName, withCompletionBlock: { (error, _) in
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
    
    private func updateLastName(lastName: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let ref = self.currentUserRef {
                ref.child("snapShot").child("lastName").setValue(lastName, withCompletionBlock: { (error, _) in
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
}