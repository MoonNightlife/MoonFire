//
//  BackendEnums.swift
//  Moon
//
//  Created by Evan Noble on 12/29/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

enum BackendResult<Value> {
    case Success(result: Value)
    case Failure(error: NSError)
}

enum BackendResponse {
    case Success
    case Failure(error: NSError)
}

enum ProviderCredentials {
    case Facebook(credentials: FacebookCredentials)
    case Google(credentials: GoogleCredentials)
    case Email(credentials: EmailCredentials)
}

enum ProfilePictureType {
    case Thumbnail
    case FullSize
}

enum UserRelation {
    case Friends
    case FriendRequestSent
    case NotFriends
    case PendingFriendRequest
}

enum UserType {
    case SignedInUser
    case OtherUser(uid: String)
}


