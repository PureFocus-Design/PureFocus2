//
//  BluetoothDevice.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/22/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import os.log

class BlueToothDevice:  NSObject, NSCoding{
    
    var uuID: UUID{
        return UUID.init(uuidString: uuIDString)!
    }
    
    var uuIDString: String = ""
    
    struct PropertyKey{
        static let uuID = "UUID"
    }
    
    // MARK NSCODING
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uuIDString, forKey: PropertyKey.uuID)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
        guard let uuIDString = aDecoder.decodeObject(forKey: PropertyKey.uuID) as? String else {
            os_log("Unable to decode the UUID for a BluetoothDevice object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.uuIDString = uuIDString
    }
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("uuID")
    
    //MARK: Private Methods
    
    private func saveUUIDs() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(uuID, toFile: BlueToothDevice.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("UUIDs successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save UUIDs.", log: OSLog.default, type: .error)
        }
    }
    private func loadUUIDs() -> [BlueToothDevice]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: BlueToothDevice.ArchiveURL.path) as? [BlueToothDevice]
    }

}
