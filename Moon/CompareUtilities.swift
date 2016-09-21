//
//  CompareUtilities.swift
//  Moon
//
//  Created by Evan Noble on 8/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

/**
 This function compares two arrays of featured bar activities and sees if they are the same
 - Author: Evan Noble
 - Parameters:
 - group1: one of the arrays to be compared
 - group2: the other array to be compared
 */
func checkIfSameFeaturedBarActivities(group1: [FeaturedBarActivity], group2: [FeaturedBarActivity]) -> Bool {
    // See if the newly pulled data is different from old data
    var sameFBActivities = true
    if group1.count != group2.count {
        sameFBActivities = false
    } else {
        for i in 0..<group1.count {
            if group1[i].featuredId != group2[i].featuredId {
                sameFBActivities = false
            }
            if group1[i].name != group2[i].name {
                sameFBActivities = false
            }
            if group1[i].description != group2[i].description {
                sameFBActivities = false
            }
            if group1[i].date != group2[i].date {
                sameFBActivities = false
            }
            if group1[i].time != group2[i].time {
                sameFBActivities = false
            }
            if group1[i].pictureUrl != group2[i].pictureUrl {
                sameFBActivities = false
            }
        }
    }
    return sameFBActivities
}

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
func checkIfSameSpecials(group1: [Special2], group2: [Special2]) -> Bool {
    // See if the newly pulled data is different from old data
    print(group1.count)
    print(group2.count)
    var sameSpecial = true
    if group1.count != group2.count {
        sameSpecial = false
    } else {
        for i in 0..<group1.count {
            if group1[i].description! != group2[i].description! {
                print(group1[i].description)
                print(group2[i].description)
                sameSpecial = false
            }
        }
    }
    return sameSpecial
}
