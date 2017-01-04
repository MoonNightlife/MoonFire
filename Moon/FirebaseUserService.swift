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
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    func isUsernameFree(username: String) -> Observable<BackendResult<Bool>>
    // The Observable string is the users uid
    func signUserIn(credentials: ProviderCredentials) -> Observable<BackendResponse>
    // If the user hasn't signed in for a while then the account must be reauthenticated first
    func deleteAccountForSignedInUser() -> Observable<BackendResponse>
    func reauthenticateAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    // A user can only save the user that they are signed into
    func saveUser(user: User2) -> Observable<BackendResponse>
    func getUser(uid: String) -> Observable<User2>
    // The phone number is saved to the online user
    func savePhoneNumber(phoneNumber: String) -> Observable<BackendResponse>
    func getFriendForUsersWith(UID uid: String) -> Observable<BackendResult<UserSnapshot>>
    func getFriendRequests() -> Observable<BackendResult<UserSnapshot>>
    func doesUserDataAleadyExistForSignedInUser() -> Observable<BackendResult<Bool>>
    func getUserProvider() -> Provider?
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
            if let currentUserRef = self.currentUserRef {
                currentUserRef.setValue(user.toJSON(), withCompletionBlock: { (error, _) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: error))
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
    
    func getUser(uid: String) -> Observable<User2> {
        return Observable.create({ (observer) -> Disposable in
            
            return AnonymousDisposable {
                
            }
            
        })
    }
    
    func signUserIn(provider: ProviderCredentials) -> Observable<BackendResponse> {
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
            
            FIRAuth.auth()?.signInWithCredential(firebaseCredentials, completion: { (authData, error) in
                if let error = error {
                    observer.onNext(BackendResponse.Failure(error: error))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()

            })
            
            return AnonymousDisposable {
                
            }
            
        })

    }
    
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
        
            switch provider {
                case .Email(let credentials):
                    
                    FIRAuth.auth()?.createUserWithEmail(credentials.email, password: credentials.password, completion: { (authData, error) in
                        if let error = error {
                            observer.onNext(BackendResponse.Failure(error: error))
                        } else {
                            //TODO: remove this once all files use a service to connect to backend
                            NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: "uid")
                            observer.onNext(BackendResponse.Success)
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
                        observer.onNext(BackendResponse.Failure(error: error))
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
                        observer.onNext(BackendResponse.Failure(error: error))
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
    
    func isUsernameFree(username: String) -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
            rootRef.child("users").queryOrderedByChild("username").queryEqualToValue(username).observeSingleEventOfType(.Value, withBlock: { (snap) in
                // If the returned value doesnt exist then return true indicating that the username is free
                if snap.value is NSNull {
                    observer.onNext(BackendResult.Success(response: true))
                } else {
                    observer.onNext(BackendResult.Success(response: false))
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
    
    func savePhoneNumber(phoneNumber: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                rootRef.child("phoneNumbers").child(user.uid).setValue(phoneNumber, withCompletionBlock: { (error, _) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: error))
                    } else {
                        observer.onNext(BackendResponse.Success)
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func getFriendForUsersWith(UID uid: String) -> Observable<BackendResult<UserSnapshot>> {
        return Observable.create({ (observer) -> Disposable in
            return AnonymousDisposable {
                
            }
        })
    }
    
    func getFriendRequests() -> Observable<BackendResult<UserSnapshot>> {
        return Observable.create({ (observer) -> Disposable in
            return AnonymousDisposable {
                
            }
        })
    }
    
    func doesUserDataAleadyExistForSignedInUser() -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
            if let ref = self.currentUserRef {
                ref.child("snapshot").observeSingleEventOfType(.Value, withBlock: { (snap) in
                    // If the returned value doesnt exist then return true indicating that the user is new
                    if snap.value is NSNull {
                        observer.onNext(BackendResult.Success(response: false))
                    } else {
                        observer.onNext(BackendResult.Success(response: true))
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
    
    // If returned nil then there is no user signed in
    func getUserProvider() -> Provider? {
        if let currentUser = user {
            for data in currentUser.providerData {
                // A user should never have both 'facebook.com' and 'google.com' as providers because this app doesn't support multiple providers, but 'firebase' will always be a provider for any user.
                if data.providerID == "facebook.com" {
                    return .Facebook
                }
                if data.providerID == "google.com" {
                    return .Google
                }
            }
            return .Firebase
        } else {
            return nil
        }
    }
    
}