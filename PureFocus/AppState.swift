//
//  AppState.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/25/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import CoreBluetooth

struct AppState{
    
    var internalAppState: AppState
    var singleAppModeState: SingleAppModeState
    var activeViewController: ActiveViewController
    
    enum ActiveViewController{
        case main
        case beacon
    }
    
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
    
    init(internalAppState: AppState, singleAppModeState: SingleAppModeState, activeViewController: ActiveViewController) {
        self.internalAppState = internalAppState
        self.singleAppModeState = singleAppModeState
        self.activeViewController = activeViewController
    }
}
