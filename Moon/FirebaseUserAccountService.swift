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

protocol UserAccountBackendService {
    
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    func isUsernameFree(username: String) -> Observable<BackendResult<Bool>>
    func signUserIn(credentials: ProviderCredentials) -> Observable<BackendResponse>
    func deleteAccountForSignedInUser() -> Observable<BackendResponse>
    func reauthenticateAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    func saveUser(user: User2) -> Observable<BackendResponse>
    func doesUserDataAleadyExistForSignedInUser() -> Observable<BackendResult<Bool>>
    func getUserProvider() -> Provider?
    func getUidForSignedInUser() -> String?
    func resetPassword(email: String) -> Observable<BackendResponse>
    
    // Move to user service
    func savePhoneNumber(phoneNumber: String) -> Observable<BackendResponse>
    func getFriendForUsersWith(UID uid: String) -> Observable<BackendResult<UserSnapshot>>
    func getFriendRequests() -> Observable<BackendResult<UserSnapshot>>
}

struct FirebaseUserAccountService: UserAccountBackendService {
    
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
    
    // A user can only save the user that they are signed into
    func saveUser(user: User2) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let currentUserRef = self.currentUserRef {
                currentUserRef.setValue(user.toJSON(), withCompletionBlock: { (error, _) in
                    if let error = error {
                        observer.onNext(BackendResponse.Failure(error: error))
                        observer.onCompleted()
                    } else {
                        self.saveUsernameToListOfUsernames(user, handler: { (error) in
                            if let error = error {
                                observer.onNext(BackendResponse.Failure(error: error))
                            } else {
                                observer.onNext(BackendResponse.Success)
                            }
                            observer.onCompleted()
                        })
                    }
                    
                })
            } else {
                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
                observer.onCompleted()
            }
            
            
            return AnonymousDisposable {
                
            }
        })

    }
    
    private func saveUsernameToListOfUsernames(user: User2, handler: (error: NSError?)->()) {
        if let username = user.userSnapshot?.username, let uid = self.user?.uid {
            rootRef.child("usernames").child(username).setValue(uid, withCompletionBlock: { (error, _) in
                handler(error: error)
            })
        } else {
            handler(error: BackendError.NoUserSignedIn)
        }
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
                firebaseCredentials = FIRGoogleAuthProvider.credentialWithIDToken(credentials.idToken, accessToken: credentials.accessToken)
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
                firebaseCredentials = FIRGoogleAuthProvider.credentialWithIDToken(credentials.idToken, accessToken: credentials.accessToken)
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
    
    // If the user hasn't signed in for a while then the account must be reauthenticated first
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
        print(FIRAuth.auth()?.currentUser?.uid)
        return Observable.create({ (observer) -> Disposable in
            rootRef.child("usernames").queryOrderedByKey().queryEqualToValue(username).observeSingleEventOfType(.Value, withBlock: { (snap) in
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
    
    // The phone number is saved for the signed in user
    func savePhoneNumber(phoneNumber: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                rootRef.child("phoneNumbers").child(phoneNumber).setValue(user.uid, withCompletionBlock: { (error, _) in
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
    
    func getUidForSignedInUser() -> String? {
        if let user = user {
            return user.uid
        } else {
            return nil
        }
    }
    
    func resetPassword(email: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            FIRAuth.auth()?.sendPasswordResetWithEmail(email) { error in
                if let error = error {
                    observer.onNext(BackendResponse.Failure(error: error))
                } else {
                    observer.onNext(BackendResponse.Success)
                }
                observer.onCompleted()
            }
            
            return AnonymousDisposable {
                
            }
        })
    }
    
}