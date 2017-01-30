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
    
    func createAccount(provider: ProviderCredentials) -> Observable<BackendResult<String>>
    func isUsernameFree(username: String) -> Observable<BackendResult<Bool>>
    
    func signUserIn(credentials: ProviderCredentials) -> Observable<BackendResult<String>>
    func logSignedInUserOut() -> Observable<BackendResponse>
    func changePasswordForSignedInUser(newPassword: String) -> Observable<BackendResponse>
    
    func deleteAccountForSignedInUser() -> Observable<BackendResponse>
    func reauthenticateAccount(provider: ProviderCredentials) -> Observable<BackendResponse>
    func saveUser(user: User2) -> Observable<BackendResponse>
    func doesUserDataAleadyExistForSignedInUser() -> Observable<BackendResult<Bool>>
    func getUserProvider() -> Provider?
    func getUidForSignedInUser() -> Observable<BackendResult<String>> 
    func resetPassword(email: String) -> Observable<BackendResponse>
    func updateEmail(email: String) -> Observable<BackendResponse>
    func getEmailForSignedInUser() -> Observable<BackendResult<String?>>
    
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
    
    func getEmailForSignedInUser() -> Observable<BackendResult<String?>> {
        return Observable.create({ (observer) -> Disposable in
            
            if let user = self.user {
                observer.onNext(BackendResult.Success(response: user.email))
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
            }
            
            observer.onCompleted()
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    // If the user hasn't signed in for a while then the account must be reauthenticated first
    func changePasswordForSignedInUser(newPassword: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            FIRAuth.auth()?.currentUser?.updatePassword(newPassword, completion: { (error) in
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
    
    func logSignedInUserOut() -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            do {
                try FIRAuth.auth()?.signOut()
                observer.onNext(BackendResponse.Success)
            } catch {
                observer.onNext(BackendResponse.Failure(error: BackendError.FailedToLogout))
            }
            
            observer.onCompleted()
            
            return AnonymousDisposable {
                
            }
        })
    }
    
    func updateEmail(email: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                user.updateEmail(email, completion: { (error) in
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
    
    
    func signUserIn(provider: ProviderCredentials) -> Observable<BackendResult<String>> {
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
                    observer.onNext(BackendResult.Failure(error: error))
                } else {
                    if let user = authData {
                        //TODO: remove this once all files use a service to connect to backend
                        NSUserDefaults.standardUserDefaults().setValue(user.uid, forKey: "uid")
                        observer.onNext(BackendResult.Success(response: user.uid))
                    } else {
                        observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
                    }
                }
                observer.onCompleted()

            })
            
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
                            observer.onNext(BackendResult.Failure(error: error))
                        } else {
                            if let user = authData {
                                //TODO: remove this once all files use a service to connect to backend
                                NSUserDefaults.standardUserDefaults().setValue(user.uid, forKey: "uid")
                                observer.onNext(BackendResult.Success(response: user.uid))
                            } else {
                                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
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
    
    //MARK: - Helper methods for deleting a user in firebase
    //TODO: Need to figure out what is required to delete
//    private func deleteFirebaseAccountForSignedInUser() -> Observable<BackendResponse> {
//        return Observable.create({ (observer) -> Disposable in
//            
//            if let user = self.user {
//                user.deleteWithCompletion({ (error) in
//                    if let error = error {
//                        observer.onNext(BackendResponse.Failure(error: error))
//                    } else {
//                        observer.onNext(BackendResponse.Success)
//                    }
//                    observer.onCompleted()
//                })
//            } else {
//                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
//                observer.onCompleted()
//            }
//            
//            return AnonymousDisposable {
//                
//            }
//        })
//    }
//    private func removeSignedInUserFromFriendsListAndBarFeedOfOtherUsers() -> Observable<BackendResponse> {
//        return Observable.create({ (observer) -> Disposable in
//            
//            
//            
//            return AnonymousDisposable {
//                
//            }
//        })
//    }
//    private func removeFriendRequestSentOutBySignInUser() -> Observable<BackendResponse> {
//        return Observable.create({ (observer) -> Disposable in
//
//            // Remove any friend request for that user
//            if let user = self.user {
//                FirebaseRefs.FriendRequest.child(user.uid).removeValueWithCompletionBlock({ (error, _) in
//                    if let e = error {
//                        observer.onNext(BackendResponse.Failure(error: e))
//                    } else {
//                        observer.onNext(BackendResponse.Success)
//                    }
//                    
//                    observer.onCompleted()
//                })
//            } else {
//                observer.onNext(BackendResponse.Failure(error: BackendError.NoUserSignedIn))
//                observer.onCompleted()
//            }
//            
//            
//            return AnonymousDisposable {
//                
//            }
//        })
//    }
//    private func removeBarActivityAndDecrementBarCountForSignedInUser() -> Observable<BackendResponse> {
//        return Observable.create({ (observer) -> Disposable in
//            
//            
//            
//            return AnonymousDisposable {
//                
//            }
//        })
//    }
    
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
        return savePhoneNumberToProfile(phoneNumber)
            .flatMap({ (response) -> Observable<BackendResponse> in
                switch response {
                case .Success:
                    return self.savePhoneNumberToList(phoneNumber)
                case .Failure(let error):
                    return Observable.just(BackendResponse.Failure(error: error))
                }
            })
    }
    
    private func savePhoneNumberToProfile(phoneNumber: String) -> Observable<BackendResponse> {
        return Observable.create({ (observer) -> Disposable in
            
            if let userRef = self.currentUserRef {
                userRef.child("profile").child("phoneNumber").setValue(phoneNumber, withCompletionBlock: { (error, _) in
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
    
    private func savePhoneNumberToList(phoneNumber: String) -> Observable<BackendResponse> {
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
                observer.onCompleted()
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
    
    func getUidForSignedInUser() -> Observable<BackendResult<String>> {
        return Observable.create({ (observer) -> Disposable in
            if let user = self.user {
                observer.onNext(BackendResult.Success(response: user.uid))
            } else {
                observer.onNext(BackendResult.Failure(error: BackendError.NoUserSignedIn))
            }
            
            observer.onCompleted()
            
            return AnonymousDisposable {
                //TODO: dispose of auth block reference
            }
        })
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