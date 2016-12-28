//
//  StringExtensions.swift
//  Moon
//
//  Created by Evan Noble on 12/8/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

extension String {
    public func toPhoneNumber() -> String {
        return stringByReplacingOccurrencesOfString("(\\d{3})(\\d{3})(\\d+)", withString: "($1) $2-$3", options: .RegularExpressionSearch, range: nil)
    }
}