//
//  AppState.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/25/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation

struct AppState{
    
    var internalAppState: AppState
    var singleAppModeState: SingleAppModeState
    var inRange: Bool = false
    
    enum AppState{
        case terminated
        case background
        case foreground
    }
    
    enum SingleAppModeState{
        case unlocked
        case lockedByDevice
        case lockedByApi
    }
    
    init(internalAppState: AppState, singleAppModeState: SingleAppModeState) {
        self.internalAppState = internalAppState
        self.singleAppModeState = singleAppModeState
    }
}

