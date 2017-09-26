//
//  BluetoothDevice.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/22/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import os.log

class BluetoothDevice:  NSObject{
    
    // test passes or fails
    
    enum BluetoothState: String{
        case rangeable     // State starts out as rangeable
        case connectable   // auto-detects connectable
        case inactive      // user can ignore certain devices
        case synced        // app has tested connection and will connect
    }
    
    var uuID: UUID
    var bluetoothState: BluetoothState
    
    init(uuID: String) {
        self.uuID = UUID.init(uuidString: uuID)!
        self.bluetoothState = .rangeable
    }
    
}
