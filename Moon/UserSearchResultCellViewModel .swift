//
//  UserSearchResultCellViewModel .swift
//  Moon
//
//  Created by Evan Noble on 2/7/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

struct UserSearchResultCellViewModel {
    
    // Services
    private let userService: UserService!
    private let photoService: PhotoService!
    private let photoUtilities: PhotoUtilities!
    
    // Inputs
    var userID = Variable<String>("")
    
    // Outputs
    var username: Observable<String>?
    var name: Observable<String>?
    var profilePicture: Observable<UIImage?>?
    
    init(userService: UserService, photoService: PhotoService, photoUtilities: PhotoUtilities) {
        self.userService = userService
        self.photoService = photoService
        self.photoUtilities = photoUtilities
        setOutputs()
    }
    
    // TODO: research to see if view model struct should contain mutating function
    mutating func setOutputs() {
        
       let userSnapshot = userID.asObservable()
                .flatMap { (userID) -> Observable<BackendResult<UserSnapshot>> in
                    return self.userService.getUserSnapshotForUserType(UserType: UserType.OtherUser(uid: userID))
                }
        
       self.username = userSnapshot
        .map({ (result) -> String in
            switch result {
            case .Success(let snapshot):
                return snapshot.username ?? ""
            case .Failure:
                return "failed to load data"
            }
        })
        
        self.name = userSnapshot
            .map({ (result) -> String in
                switch result {
                case .Success(let snapshot):
                    let firstName = snapshot.firstName ?? ""
                    let lastName = snapshot.lastName ?? ""
                    return firstName + lastName
                case .Failure:
                    return "failed to load data"
                }
            })
        
        self.profilePicture = userID.asObservable()
                .flatMapLatest({ (userID) ->  Observable<BackendResult<NSURL>> in
                    return self.photoService.getProfilePictureUrlFor(UserID: userID, type: ProfilePictureType.Thumbnail)
                })
                .flatMapLatest({ (result) -> Observable<PhotoResult<UIImage>> in
                    switch result {
                    case .Success(let url):
                        return self.photoUtilities.getPhotoFor(URL: url.absoluteString)
                    case .Failure(let error):
                        return Observable.just(PhotoResult.Failure(error: error))
                    }
                })
                .map {
                    switch $0 {
                    case .Success(let image):
                        return image
                    case .Failure(let error):
                        print(error)
                        return nil
                    }
                }
    }
    
}