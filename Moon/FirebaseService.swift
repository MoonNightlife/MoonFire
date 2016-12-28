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

protocol BackendService {
    // The Observable string is the users uid
    func createAccount(provider: ProviderCredentials) -> Observable<String>
    func isUsernameFree(username: String) -> Observable<Bool>
    // The Observable string is the users uid
    func signUserIn(credentials: ProviderCredentials) -> Observable<String>
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

enum FirebaseServiceErrors: ErrorType {
    case NoAuthUserData
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
    
    func signUserIn(provider: ProviderCredentials) -> Observable<String> {
        return Observable.create({ (observer) -> Disposable in
            
            switch provider {
                case .Email(let credentials):
                    
                    FIRAuth.auth()?.signInWithEmail(credentials.email, password: credentials.password, completion: { (authData, error) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            if let userData = authData {
                                observer.onNext(userData.uid)
                            } else {
                                observer.onError(FirebaseServiceErrors.NoAuthUserData)
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
    
    func createAccount(provider: ProviderCredentials) -> Observable<String> {
        return Observable.create({ (observer) -> Disposable in
        
            switch provider {
                case .Email(let credentials):
                    
                    FIRAuth.auth()?.createUserWithEmail(credentials.email, password: credentials.password, completion: { (authData, error) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            if let data = authData {
                                observer.onNext(data.uid)
                            } else {
                                observer.onError(FirebaseServiceErrors.NoAuthUserData)
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