//
//  BluetoothDevice.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/22/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import os.log
import CoreBluetooth

// Wrote this class before trying to connect to bluetooth devices
// CBPeripheral is identical

class BluetoothDevice: NSObject{
    
    let uuID: UUID
    var name: String = "unknown"
    var bluetoothState: BluetoothState
    
    enum BluetoothState: String{
        case rangeable     // State starts out as rangeable
        case connectable   // auto-detects connectable
        case inactive      // user can ignore certain devices
        case synced        // app has tested connection and will connect
    }
    
    init(uuID: String) {
        self.uuID = UUID.init(uuidString: uuID)!
        self.bluetoothState = .rangeable
    }
    override var description: String{
        return ("name: \(self.name), UUID: \(uuID.uuidString)")
    }
    
}
