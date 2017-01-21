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
import ObjectMapper

protocol UserBackendService {
    
    func getSignedInUserInformation() -> Observable<BackendResult<User2>>
    
    func updateName(firstName: String, lastName: String) -> Observable<BackendResponse>
    func updatePrivacy(isOn: Bool) -> Observable<BackendResponse>
    func updateBirthday(date: String) -> Observable<BackendResponse>
    func updateSex(sex: String) -> Observable<BackendResponse>
    func updateEmail(email: String) -> Observable<BackendResponse>
    func updateFavoriteDrink(drink: String) -> Observable<BackendResponse>
    func updateCity(city: City2?) -> Observable<BackendResponse>
    func updateBio(bio: String) -> Observable<BackendResponse>
    
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
    
    func updateBio(bio: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            self.currentUserRef?.child("profile").child("bio").setValue(bio, withCompletionBlock: { (error, _) in
                if let e = error {
                    observer.onNext(BackendResponse.Failure(error: e))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func updateBirthday(date: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            self.currentUserRef?.child("profile").child("birthday").setValue(date, withCompletionBlock: { (error, _) in
                if let e = error {
                    observer.onNext(BackendResponse.Failure(error: e))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func updateSex(sex: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            self.currentUserRef?.child("profile").child("sex").setValue(sex, withCompletionBlock: { (error, _) in
                if let e = error {
                    observer.onNext(BackendResponse.Failure(error: e))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func updateEmail(email: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func updateFavoriteDrink(drink: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            self.currentUserRef?.child("profile").child("favoriteDrink").setValue(drink, withCompletionBlock: { (error, _) in
                if let e = error {
                    observer.onNext(BackendResponse.Failure(error: e))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            })
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    // If there is no city passed in then remove the simLocation for the user
    // If there is no simLocation then the app will us the users location instead
    func updateCity(city: City2?) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            if let city = city {
                
                self.currentUserRef?.child("profile").child("simLocation").setValue(city.cityId, withCompletionBlock: { (error, _) in
                    if let e = error {
                        observer.onNext(BackendResponse.Failure(error: e))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()
                })
            } else {
                self.currentUserRef?.child("profile").child("simLocation").removeValueWithCompletionBlock({ (error, _) in
                    if let e = error {
                        observer.onNext(BackendResponse.Failure(error: e))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()
                })
            }
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func getSignedInUserInformation() -> Observable<BackendResult<User2>> {
        return Observable.combineLatest(getSignedInUserSnapshot(), getSignedInUserProfile(), resultSelector: { (userSnapshot, userProfile) in
            
            var snapshot: UserSnapshot?
            var profile: UserProfile?
            var e: NSError?
            
            switch userSnapshot {
            case .Success(let snap):
                snapshot = snap
            case .Failure(let error):
                e = error
            }
            
            switch userProfile {
            case .Success(let prof):
                profile = prof
            case .Failure(let error):
                e = error
            }
            
            if let e = e {
                return .Failure(error: e)
            } else if let snap = snapshot, let prof = profile {
                return BackendResult.Success(response: User2(userSnapshot: snap, userProfile: prof))
            } else {
                return BackendResult.Failure(error: BackendError.CounldNotGetUserInformation)
            }
            
        })
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
                ref.child("snapshot").updateChildValues(["privacy": isOn])
                observer.onNext(BackendResponse.Success)
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
            }
            return AnonymousDisposable {
                
            }
        })
    }
    
    private func getSignedInUserProfile() -> Observable<BackendResult<UserProfile>> {
        return Observable.create({ (observer) -> Disposable in
            
            let handle = self.currentUserRef?.child("profile").observeEventType(.Value, withBlock: { (user) in
                if !(user.value is NSNull), let userProfileInfo = user.value as? [String : AnyObject] {
                    
                    let userProfile = Mapper<UserProfile>().map(userProfileInfo)
                    
                    if let userProfile = userProfile {
                        observer.onNext(BackendResult.Success(response: userProfile))
                    }
                }
                
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })
            
            
            return AnonymousDisposable {
                if let h = handle {
                    rootRef.removeObserverWithHandle(h)
                }
            }
            
        })

    }
    
    private func getSignedInUserSnapshot() -> Observable<BackendResult<UserSnapshot>> {
        return Observable.create({ (observer) -> Disposable in
            
            let handle = self.currentUserRef?.child("snapshot").observeEventType(.Value, withBlock: { (user) in
                if !(user.value is NSNull), let userProfileInfo = user.value as? [String : AnyObject] {
            
                    let userId = Context(id: self.currentUserRef?.key)
                    let userSnapshot = Mapper<UserSnapshot>(context: userId).map(userProfileInfo)
            
                    if let userSnap = userSnapshot {
                        observer.onNext(BackendResult.Success(response: userSnap))
                    }
                }
                
                }, withCancelBlock: { (error) in
                    observer.onNext(BackendResult.Failure(error: error))
                    observer.onCompleted()
            })

            
            return AnonymousDisposable {
                if let h = handle {
                    rootRef.removeObserverWithHandle(h)
                }
            }
            
        })
    }
    
    private func updateFirstName(firstName: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let ref = self.currentUserRef {
                ref.child("snapshot").child("firstName").setValue(firstName, withCompletionBlock: { (error, _) in
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
                ref.child("snapshot").child("lastName").setValue(lastName, withCompletionBlock: { (error, _) in
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