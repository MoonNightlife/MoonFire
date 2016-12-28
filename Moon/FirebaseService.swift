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

enum BackendResult<Value> {
    case Success(response: Value)
    case Failure(error: BackendError)
}

protocol BackendService {
    // The Observable string is the users uid
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResult<String>>
    func isUsernameFree(username: String) -> Observable<Bool>
    // The Observable string is the users uid
    func signUserIn(credentials: ProviderCredentials) -> Observable<BackendResult<String>>
    func deleteAccount(provider: ProviderCredentials) -> Observable<BackendResult<Bool>>
    func saveUser(user: User2)
    func getUser(uid: String) -> Observable<User2>
}

struct FacebookCredentials {
    
}

struct GoogleCredentials {
    
}

struct EmailCredentials {
    let email: String
    let password: String
}

enum ProviderCredentials {
    case Facebook(credentials: FacebookCredentials)
    case Google(credentials: GoogleCredentials)
    case Email(credentials: EmailCredentials)
}

enum SignInResponse {
    case Success(uid: String)
    case Error(message: String)
}

struct FirebaseService: BackendService {
    
    var currentUser: FIRDatabaseReference? {
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            let currentUser = rootRef.child("users").child(userID)
            return currentUser
        } else {
            return nil
        }
    }
    
    func saveUser(user: User2) {
        currentUser?.setValue(user.toJSON())
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
    
    func deleteAccount(provider: ProviderCredentials) -> Observable<BackendResult<Bool>> {
        return Observable.create({ (observer) -> Disposable in
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