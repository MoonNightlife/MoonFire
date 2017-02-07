//
//  FirebaseSearchService.swift
//  Moon
//
//  Created by Evan Noble on 2/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import ObjectMapper
import RxSwift
import Firebase

enum SearchField {
    case Username
    case FirstName
    case LastName
}

protocol SearchService {
    func searchForUserIDsWith(SearchText text: String) -> Observable<BackendResult<[String]>>
    //func searchForBarWithName(searchText: String) -> Observable<BackendResult<Bar2>>
}

struct FirebaseSearchService: SearchService {
    
    // This function searches for the username, first name, and last name
    func searchForUserIDsWith(SearchText text: String) -> Observable<BackendResult<[String]>> {
        return searchForUserIDsWithMatching(Username: text)
        
    }
    
    private func searchForUserIDsWithMatching(Username searchText: String) -> Observable<BackendResult<[String]>> {
        return Observable.create({ (observer) -> Disposable in
            
            let SearchSizeLimit: UInt = 25
            
            FirebaseRefs.Usernames
                .queryOrderedByKey()
                .queryStartingAtValue(searchText)
                .queryLimitedToFirst(SearchSizeLimit)
                .observeSingleEventOfType(.Value, withBlock: { (snap) in
                    
                    
                    var userIDs = [String]()
                    
                    for userID in snap.children {
                        let id = (userID as? FIRDataSnapshot)
                        if let userID = id?.value as? String {
                            userIDs.append(userID)
                        }
                    }
                    
                    observer.onNext(BackendResult.Success(result: userIDs))
                    observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })

            
            return AnonymousDisposable {
                
            }
        })
    }
    
    
    // This function does not work
    // Need to find out how to search 2 nodes deep on a user for this to be used
    private func searchForUsersWith(SearchField field: SearchField, SearchText searchText: String) -> Observable<BackendResult<[UserSnapshot]>> {
        return Observable.create({ (observer) -> Disposable in
            
            let SearchSizeLimit: UInt = 25
            let firebaseSearchField: String
            
            switch field {
            case .Username:
                firebaseSearchField = "username"
            case .FirstName:
                firebaseSearchField = "firstName"
            case .LastName:
                firebaseSearchField = "lastName"
            }
            
            FirebaseRefs.Users
                .queryOrderedByChild("snapshot/\(firebaseSearchField)")
                .queryStartingAtValue(searchText)
                .queryLimitedToFirst(SearchSizeLimit)
                .observeSingleEventOfType(.Value, withBlock: { (snap) in
                    
                    var snapshots = [UserSnapshot]()
                    
                    for userSnap in snap.children {
                        if let snapshot = userSnap as? [String : AnyObject] {
                            let uid = snap.key
                            let userId = Context(id: uid)
                            let userSnapshot = Mapper<UserSnapshot>(context: userId).map(snapshot)
                            
                            if let userSnap = userSnapshot {
                                snapshots.append(userSnap)
                            }
                        }
                    }
                    
                    observer.onNext(BackendResult.Success(result: snapshots))
                    observer.onCompleted()
                    
                    }, withCancelBlock: { (error) in
                        observer.onNext(BackendResult.Failure(error: error))
                        observer.onCompleted()
                })
            
            return AnonymousDisposable {
                
            }
        })
    }
    
//    func searchForBarWithName(searchText: String) -> Observable<BackendResult<Bar2>> {
//        
//    }
    
}