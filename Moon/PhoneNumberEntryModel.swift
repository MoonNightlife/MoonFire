//
//  PhoneNumberEntryModel.swift
//  Moon
//
//  Created by Evan Noble on 12/6/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

struct PhoneNumberEntryModel {
    var phoneNumber: String?
    var verificationCode: String?
    var formattedPhoneNumber: String?
    var isVerified: Bool?
}