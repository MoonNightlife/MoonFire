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



protocol UserService {
    
    func getUserInformationFor(UserType type: UserType) -> Observable<BackendResult<User2>>
    func getUserSnapshotForUserType(UserType type: UserType) -> Observable<BackendResult<UserSnapshot>>
    func getUsernameFor(UserType type: UserType) -> Observable<BackendResult<String>>
    
    func updateName(firstName: String, lastName: String) -> Observable<BackendResponse>
    func updatePrivacy(isOn: Bool) -> Observable<BackendResponse>
    func updateBirthday(date: String) -> Observable<BackendResponse>
    func updateSex(sex: String) -> Observable<BackendResponse>
    func updateEmail(email: String) -> Observable<BackendResponse>
    func updateFavoriteDrink(drink: String) -> Observable<BackendResponse>
    func updateCity(city: City2?) -> Observable<BackendResponse>
    func updateBio(bio: String) -> Observable<BackendResponse>
    func updateFavoriteBar(barID: String) -> Observable<BackendResponse>
    
    func unfriendUserWith(UserID id: String) -> Observable<BackendResponse>
    func acceptFriendRequestForUserWith(UserID id: String) -> Observable<BackendResponse>
    func sendFriendRequestToUserWith(UserID id: String) -> Observable<BackendResponse>
    func cancelFriendRequestToUserWith(UserID id: String) -> Observable<BackendResponse>
    func getUserRelationToUserWith(UserID id: String) -> Observable<BackendResult<UserRelation>>
    func checkForFriendRequestForSignInUser() -> Observable<BackendResult<UInt>>
    func getFriendRequestIDs() -> Observable<BackendResult<String>>
    
}

struct FirebaseUserService: UserService {
    
    private var user: FIRUser? {
        return FIRAuth.auth()?.currentUser
    }
    
    func updateFavoriteBar(barID: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("profile").child("favoriteBar").setValue(barID, withCompletionBlock: { (error, _) in
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
    
    // Returns the number of friend request the user has
    func checkForFriendRequestForSignInUser() -> Observable<BackendResult<UInt>> {
        return Observable.create({ (observer) -> Disposable in
            
            var handle: UInt?
            
            if let user = self.user {
                //TODO: figure out to dispose of handle
                handle = FirebaseRefs.FriendRequest.child(user.uid).observeEventType(.Value, withBlock: { (snap) in
                        observer.onNext(BackendResult.Success(result: snap.childrenCount))
                        observer.onCompleted()
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                if let h = handle {
                    rootRef.removeObserverWithHandle(h)
                }
            }
        })
    }
    
    func getFriendRequestIDs() -> Observable<BackendResult<String>> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(user.uid).observeEventType(.Value, withBlock: { (snap) in
                    for userID in snap.children {
                        observer.onNext(BackendResult.Success(result: userID.key))
                    }
                    observer.onCompleted()
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                        observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })

    }
    
    func getUserRelationToUserWith(UserID id: String) -> Observable<BackendResult<UserRelation>> {
        return Observable.combineLatest(hasFriendRequestFromUserWith(UserID: id), hasSentFriendRequestToUserWith(UserID: id), isFriendsWithUserWith(UserID: id), resultSelector: { (hasFriendRequestResult, hasSentFriendRequestResult, isFriendResult) -> BackendResult<UserRelation> in
            
            var error: NSError?
            var userRelation: UserRelation?
            
            switch hasFriendRequestResult {
            case .Success(let hasFriendRequest):
                if hasFriendRequest {
                    userRelation = UserRelation.PendingFriendRequest
                }
            case .Failure(let e):
                error = e
            }
            
            
            switch hasSentFriendRequestResult {
            case .Success(let hasSentFriendRequest):
                if hasSentFriendRequest {
                    userRelation = UserRelation.FriendRequestSent
                }
            case .Failure(let e):
                error = e
            }
            
            switch isFriendResult {
            case .Success(let isFriend):
                if isFriend {
                    userRelation = UserRelation.Friends
                }
            case .Failure(let e):
                error = e
            }
            
            if let error = error {
                return BackendResult.Failure(error: error)
            } else if let relation = userRelation {
                return BackendResult.Success(result: relation)
            } else {
                return BackendResult.Success(result: UserRelation.NotFriends)
            }

        })
    }
    private func hasFriendRequestFromUserWith(UserID id: String) -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(user.uid).child(id).observeEventType(.Value, withBlock: { (snap) in
                        if !(snap.value is NSNull) {
                            observer.onNext(BackendResult.Success(result: true))
                        } else {
                            observer.onNext(BackendResult.Success(result: false))
                        }
                        observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    private func hasSentFriendRequestToUserWith(UserID id: String) -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(id).child(user.uid).observeEventType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull) {
                        observer.onNext(BackendResult.Success(result: true))
                    } else {
                        observer.onNext(BackendResult.Success(result: false))
                    }
                    observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })

            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    private func isFriendsWithUserWith(UserID id: String) -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.Friends.child(user.uid).child(id).observeEventType(.Value, withBlock: { (snap) in
                    if !(snap.value is NSNull), let isFriend = snap.value as? Bool {
                        observer.onNext(BackendResult.Success(result: isFriend))
                    } else {
                        observer.onNext(BackendResult.Success(result: false))
                    }
                    observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })

            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func getUsernameFor(UserType type: UserType) -> Observable<BackendResult<String>> {
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
            
            
            FirebaseRefs.Users.child(userID).child("snapshot").child("username").observeSingleEventOfType(.Value, withBlock: { (snap) in
                if let username = snap.value as? String {
                    observer.onNext(BackendResult.Success(result: username))
                } else {
                    observer.onNext(BackendResult.Failure(error: BackendError.CounldNotGetUserInformation))
                }
                observer.onCompleted()
            })
        
            
            
            return AnonymousDisposable {
                
            }
        })
        
    }
    
    func cancelFriendRequestToUserWith(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(id).child(user.uid).removeValueWithCompletionBlock({ (error, _) in
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
    
    func unfriendUserWith(UserID id: String) -> Observable<BackendResponse> {
                    
        return removeSignedInUserIDFromFriendListOfUserWith(UserID: id)
            .flatMapFirst({ (response) -> Observable<BackendResponse> in
                switch response {
                case .Success:
                    return self.removeUserWithUserIDFromFriendsListOfSignedInUser(id)
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })

    }
    
    private func removeSignedInUserIDFromFriendListOfUserWith(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Friends.child(id).child(user.uid).removeValueWithCompletionBlock({ (error, _) in
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
    private func removeUserWithUserIDFromFriendsListOfSignedInUser(id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Friends.child(user.uid).child(id).removeValueWithCompletionBlock({ (error, _) in
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
    
    func acceptFriendRequestForUserWith(UserID id: String) -> Observable<BackendResponse> {
        return addSignedInUserIDToFriendListOfUserWith(UserID: id)
                    .flatMapFirst({ (response) -> Observable<BackendResponse> in
                        switch response {
                        case .Success:
                            return self.addUserIDToFriendListOfSignedInUser(id)
                        case .Failure(let error):
                            return Observable.just(BackendResponse.Failure(error: error))
                        }
                    })
                    .flatMapFirst({ (response) -> Observable<BackendResponse> in
                        switch response {
                        case .Success:
                            return self.removeFriendRequestFromUserWith(UserID: id)
                        case .Failure(let error):
                            return Observable.just(BackendResponse.Failure(error: error))
                        }
                    })
    }
    
    private func addUserIDToFriendListOfSignedInUser(id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Friends.child(user.uid).child(id).setValue(true, withCompletionBlock: { (error, _) in
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
    private func addSignedInUserIDToFriendListOfUserWith(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Friends.child(id).child(user.uid).setValue(true, withCompletionBlock: { (error, _) in
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
    
    // Removes the friend request sent to the signed in user from the id provided as a parameter
    private func removeFriendRequestFromUserWith(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(user.uid).child(id).removeValueWithCompletionBlock({ (error, _) in
                    
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
    
    func sendFriendRequestToUserWith(UserID id: String) -> Observable<BackendResponse> {
        return addCurrentUserIDToFriendsList(UserID: id)
            .flatMap({ (response) -> Observable<BackendResponse> in
                switch response {
                case .Success:
                    return self.addCurrentUserIDToFriendRequest(UserID: id)
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
    }
    
    private func addCurrentUserIDToFriendRequest(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.FriendRequest.child(id).child(user.uid).setValue(true, withCompletionBlock: { (error, _) in
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
    
    // This is needed because of privacy settings. The user can only edit the friends list of another user for his own ID. The ID will be added but set to false untill the user accepts it.
    private func addCurrentUserIDToFriendsList(UserID id: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Friends.child(id).child(user.uid).setValue(false, withCompletionBlock: { (error, _) in
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
    
    
    func updateBio(bio: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("profile").child("bio").setValue(bio, withCompletionBlock: { (error, _) in
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
    
    func updateBirthday(date: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("profile").child("birthday").setValue(date, withCompletionBlock: { (error, _) in
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
    
    func updateSex(sex: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            if let user = self.user {
               FirebaseRefs.Users.child(user.uid).child("profile").child("sex").setValue(sex, withCompletionBlock: { (error, _) in
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
    
    func updateEmail(email: String) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func updateFavoriteDrink(drink: String) -> Observable<BackendResponse> {
      
        return Observable.create { (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("profile").child("favoriteDrink").setValue(drink, withCompletionBlock: { (error, _) in
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
    
    // If there is no city passed in then remove the simLocation for the user
    // If there is no simLocation then the app will us the users location instead
    func updateCity(city: City2?) -> Observable<BackendResponse> {
        return Observable.create { (observer) -> Disposable in
            
            if let user = self.user {
                if let city = city {
                    FirebaseRefs.Users.child(user.uid).child("profile").child("simLocation").setValue(city.cityId, withCompletionBlock: { (error, _) in
                        if let e = error {
                            observer.onNext(BackendResponse.Failure(error: e))
                        } else {
                            observer.onNext(BackendResponse.Success)
                        }
                        observer.onCompleted()
                    })
                } else {
                    FirebaseRefs.Users.child(user.uid).child("profile").child("simLocation").removeValueWithCompletionBlock({ (error, _) in
                        if let e = error {
                            observer.onNext(BackendResponse.Failure(error: e))
                        } else {
                            observer.onNext(BackendResponse.Success)
                        }
                        observer.onCompleted()
                    })
                }

            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            
            return AnonymousDisposable {
                
            }
        }
    }
    
    func getUserInformationFor(UserType type: UserType) -> Observable<BackendResult<User2>> {
        
        return Observable.combineLatest(getUserSnapshotForUserType(UserType: type), getUserProfile(UserType: type), resultSelector: { (userSnapshot, userProfile) in
            
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
                return BackendResult.Success(result: User2(userSnapshot: snap, userProfile: prof))
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
            
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("snapshot").updateChildValues(["privacy": isOn], withCompletionBlock: { (error, _) in
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
    
    private func getUserProfile(UserType type: UserType) -> Observable<BackendResult<UserProfile>> {
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
            
            
            FirebaseRefs.Users.child(userID).child("profile").observeSingleEventOfType(.Value, withBlock: { (user) in
                if !(user.value is NSNull), let userProfileInfo = user.value as? [String : AnyObject] {
                    
                    let userProfile = Mapper<UserProfile>().map(userProfileInfo)
                    
                    if let userProfile = userProfile {
                        observer.onNext(.Success(result: userProfile))
                    }
                }
                
                }, withCancelBlock: { (error) in
                    observer.onNext(.Failure(error: error))
                    observer.onCompleted()
            })
            
            return AnonymousDisposable {
            
            }
            
        })

    }
    
    func getUserSnapshotForUserType(UserType type: UserType) -> Observable<BackendResult<UserSnapshot>> {
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
            
            FirebaseRefs.Users.child(userID).child("snapshot").observeSingleEventOfType(.Value, withBlock: { (user) in
                if !(user.value is NSNull), let userProfileInfo = user.value as? [String : AnyObject] {
                    
                    let userId = Context(id: userID)
                    let userSnapshot = Mapper<UserSnapshot>(context: userId).map(userProfileInfo)
                    
                    if let userSnap = userSnapshot {
                        observer.onNext(.Success(result: userSnap))
                    }
                    observer.onCompleted()
                }
                
                }, withCancelBlock: { (error) in
                    observer.onNext(.Failure(error: error))
                    observer.onCompleted()
            })
            
            
            return AnonymousDisposable {
                
            }
            
        })
    }
    
    private func updateFirstName(firstName: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("snapshot").child("firstName").setValue(firstName, withCompletionBlock: { (error, _) in
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
            
            if let user = self.user {
                FirebaseRefs.Users.child(user.uid).child("snapshot").child("lastName").setValue(lastName, withCompletionBlock: { (error, _) in
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