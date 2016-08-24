//
//  NSTimerExtension.swift
//  Moon
//
//  Created by Evan Noble on 8/24/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation

public typealias FLTimerBlock = (timeinterval:NSTimeInterval) -> Void

extension NSTimer
{
    private class TimerBlockContainer {
        private(set) var timerBlock:FLTimerBlock
        
        init( timerBlock:FLTimerBlock ) {
            self.timerBlock = timerBlock;
        }
    }
    
    public class func scheduledTimerWithTimeInterval(timeInterval:NSTimeInterval,
                                                     repeats:Bool = false,
                                                     block:FLTimerBlock) -> NSTimer
    {
        return self.scheduledTimerWithTimeInterval(timeInterval,
                                                   target: self,
                                                   selector:#selector(NSTimer._executeBlockFromTimer(_:)),
                                                   userInfo:TimerBlockContainer(timerBlock:block),
                                                   repeats:repeats)
    }
    
    @objc class func _executeBlockFromTimer( timer:NSTimer ) {
        if let timerBlockContainer = timer.userInfo as? TimerBlockContainer {
            timerBlockContainer.timerBlock(timeinterval:timer.timeInterval)
        }
    }
}