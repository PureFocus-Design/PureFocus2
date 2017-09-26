//
//  User.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/24/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//


import Foundation
import os.log

// permanent data stored here, dynamic data stored in app state

class User:  NSObject, NSCoding{
    
    var username: String = ""
    
    var bluetoothDevices: [BluetoothDevice] = []
    
    var locationTrackingAuthorized: Bool = false
    
    struct PropertyKey{
        static let username = "username"
        static let bluetoothDevices = "bluetoothDevices"
        static let locationTrackingAuthorized = "locationTrackingAuthorized"
    }
    
    // MARK NSCODING
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(username, forKey: PropertyKey.username)
        aCoder.encode(bluetoothDevices, forKey: PropertyKey.bluetoothDevices)
        aCoder.encode(locationTrackingAuthorized, forKey: PropertyKey.locationTrackingAuthorized)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
        guard let username = aDecoder.decodeObject(forKey: PropertyKey.username) as? String else {
            os_log("Unable to decode the username for a User object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.username = username
        guard let bluetoothDevices = aDecoder.decodeObject(forKey: PropertyKey.bluetoothDevices) as? [BluetoothDevice] else {
            os_log("Unable to decode the bluetoothDevices for a User object.", log: OSLog.default, type: .debug)
            return nil
        }        
        self.bluetoothDevices = bluetoothDevices
        self.locationTrackingAuthorized = aDecoder.decodeBool(forKey: PropertyKey.locationTrackingAuthorized)
    }
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("users")
    
    //MARK: Private Methods
    
    private func saveUsers() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: User.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Users successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save Users.", log: OSLog.default, type: .error)
        }
    }
    private func loadUsers() -> [User]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveURL.path) as? [User]
    }
    
}
