//
//  CompareUtilities.swift
//  Moon
//
//  Created by Evan Noble on 8/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

/**
 This function compares two arrays of bar activities and sees if they are the same
 - Author: Evan Noble
 - Parameters:
 - group1: one of the arrays to be compared
 - group2: the other array to be compared
 */
func checkIfSameBarActivities(group1: [BarActivity2], group2: [BarActivity2]) -> Bool {
    // See if the newly pulled data is different from old data
    var sameActivities = true
    if group1.count != group2.count {
        sameActivities = false
    } else {
        for i in 0..<group1.count {
            if group1[i].userId != group2[i].userId {
                sameActivities = false
            }
            if group1[i].time != group2[i].time {
                sameActivities = false
            }
            if group1[i].barId != group2[i].barId {
                sameActivities = false
            }
        }
    }
    return sameActivities
}

/**
 This function compares two arrays of specials and sees if they are the same
 - Author: Evan Noble
 - Parameters:
 - group1: one of the arrays to be compared
 - group2: the other array to be compared
 */
func checkIfSameSpecials(group1: [Special], group2: [Special]) -> Bool {
    // See if the newly pulled data is different from old data
    var sameSpecial = true
    if group1.count != group2.count {
        sameSpecial = false
    } else {
        for i in 0..<group1.count {
            if group1[i].description != group2[i].description {
                sameSpecial = false
            }
        }
    }
    return sameSpecial
}