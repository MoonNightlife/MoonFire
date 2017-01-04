//
//  OverlayService.swift
//  Moon
//
//  Created by Evan Noble on 12/8/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SwiftOverlays

enum OverlayType {
    case Blocking
    case NonBlocking
}

enum OverlayAction {
    case Remove
    case Show(options: OverlayOptions)
}

struct OverlayOptions {
    var message: String?
    var type: OverlayType
    
    init(message: String? = nil, type: OverlayType = .NonBlocking) {
        self.message = message
        self.type = type
    }
}


protocol OverlayRenderer {
    func presentOverlayWith(Options options: OverlayOptions)
    func removeOverlay()
}

extension OverlayRenderer where Self: UIViewController {
    func presentOverlayWith(Options options: OverlayOptions) {
        switch options.type {
        case .Blocking:
            if let message = options.message {
                SwiftOverlays.showBlockingWaitOverlayWithText(message)
            } else {
                SwiftOverlays.showBlockingWaitOverlay()
            }
        case .NonBlocking:
            if let message = options.message {
                showWaitOverlayWithText(message)
            } else {
                showWaitOverlay()
            }
        }
    }
    
    func removeOverlay() {
        SwiftOverlays.removeAllBlockingOverlays()
        removeAllOverlays()
    }
}
