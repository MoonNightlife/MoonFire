//
//  FirebaseService.swift
//  Moon
//
//  Created by Evan Noble on 11/15/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

protocol UserBackendService {
    // The Observable string is the users uid
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResult<String>>
    func isUsernameFree(username: String) -> Observable<Bool>
    // The Observable string is the users uid
    func signUserIn(credentials: ProviderCredentials) -> Observable<BackendResult<String>>
    // If the user hasn't signed in for a while then the account must be reauthenticated first
    func deleteAccountForSignedInUser() -> Observable<BackendResponse>
    func reauthenticateAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    func saveUser(user: User2) -> Observable<BackendResponse>
    func getUserProfile(uid: String) -> Observable<User2>
    func getFriendsForUser(uid: String) -> Observable<[User2]>
    func getFriendRequestForUser(uid: String) -> Observable<[User2]>
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
    
    func saveUser(user: User2) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let userID = user.userId {
                rootRef.child("users").child(userID).setValue(user.toJSON(), withCompletionBlock: { (error, _) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: convertFirebaseErrorToBackendErrorType(error)))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.UserHasNoUserID))
                observer.onCompleted()
            }
         
            return AnonymousDisposable {
                
            }
        })
        
        
        currentUserRef?.setValue(user.toJSON())
    }
    
    func getUser(uid: String) -> Observable<User2> {
        return Observable.create({ (observer) -> Disposable in
            
            return AnonymousDisposable {
                
            }
            
        })
    }
    
    func signUserIn(provider: ProviderCredentials) -> Observable<BackendResult<String>> {
        return Observable.create({ (observer) -> Disposable in
            
            switch provider {
                case .Email(let credentials):
                    
                    FIRAuth.auth()?.signInWithEmail(credentials.email, password: credentials.password, completion: { (authData, error) in
                        if let error = error {
                            observer.onNext(BackendResult.Failure(error: convertFirebaseErrorToBackendErrorType(error)))
                        } else {
                            if let userData = authData?.uid {
                                observer.onNext(BackendResult.Success(response: userData))
                            } else {
                                observer.onNext(BackendResult.Failure(error: BackendError.UnknownError))
                            }
                        }
                        observer.onCompleted()
                    })
                case .Facebook(let credentials): break
                case .Google(let credentials): break
            }
            
            return AnonymousDisposable {
                
            }
            
        })

    }
    
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResult<String>> {
        return Observable.create({ (observer) -> Disposable in
        
            switch provider {
                case .Email(let credentials):
                    
                    FIRAuth.auth()?.createUserWithEmail(credentials.email, password: credentials.password, completion: { (authData, error) in
                        if let error = error {
                            observer.onNext(BackendResult.Failure(error: convertFirebaseErrorToBackendErrorType(error)))
                        } else {
                            if let userData = authData?.uid {
                                observer.onNext(BackendResult.Success(response: userData))
                            } else {
                                observer.onNext(BackendResult.Failure(error: BackendError.UnknownError))
                            }
                        }
                        observer.onCompleted()
                    })
                
                case .Facebook(let credentials): break
                case .Google(let credentials): break
            }
            
        return AnonymousDisposable {
            
        }
            
        })
    }
    
    func reauthenticateAccount(provider: ProviderCredentials) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            var firebaseCredentials: FIRAuthCredential
            
            switch provider {
            case .Email(let credentials):
                firebaseCredentials = FIREmailPasswordAuthProvider.credentialWithEmail(credentials.email, password: credentials.password)
            case .Facebook(let credentials):
                firebaseCredentials = FIRFacebookAuthProvider.credentialWithAccessToken(credentials.accessToken)
            case .Google(let credentials):
                firebaseCredentials = FIRGoogleAuthProvider.credentialWithIDToken(credentials.IDToken, accessToken: credentials.accessToken)
            }
            
            if let user = self.user {
                user.reauthenticateWithCredential(firebaseCredentials, completion: { (error) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: convertFirebaseErrorToBackendErrorType(error)))
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
    
    
    func deleteAccountForSignedInUser() -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                user.deleteWithCompletion({ (error) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: convertFirebaseErrorToBackendErrorType(error)))
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
    
    func isUsernameFree(username: String) -> Observable<Bool> {
        return Observable.create({ (observer) -> Disposable in
            rootRef.child("users").queryOrderedByChild("username").queryEqualToValue(username).observeSingleEventOfType(.Value, withBlock: { (snap) in
                // If the returned value (username) doesnt exist then return true
                if snap.value is NSNull {
                    observer.onNext(true)
                } else {
                    observer.onNext(false)
                }
                observer.onCompleted()
            })
            return AnonymousDisposable {
                
            }
        })
    }
    
    
}