//
//  CallDirectoryHandler.swift
//  CallManager
//
//  Created by Ryan Dines on 8/15/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {
    
    // var blockList: [CXCallDirectoryPhoneNumber] = []
        // [CXCallDirectoryPhoneNumber.init(exactly: 17274531901)!]
    let defaults = UserDefaults(suiteName: "group.purefocus")!
    var isBlocked: Bool {
        return defaults.bool(forKey: "beaconInRange")
    }
    
    var blockList: [CXCallDirectoryPhoneNumber]{
        if isBlocked{
            return [CXCallDirectoryPhoneNumber.init(exactly: 17274531901)!]
        }
        return []
    }
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        print("Inside of CallDirectoryHandler.beginRequest, checking isBlocked:  ")
        let defaults = UserDefaults.standard
        var isBlocked: Bool {
            return defaults.bool(forKey: "beaconInRange")
        }
        print(isBlocked)
        context.delegate = self
        
        do {
            try addBlockingPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add blocking phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 1, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        do {
            try addIdentificationPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add identification phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 2, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        context.completeRequest()
    }
    
    private func addBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        
        /*
        for i in 17270000000...17279999999{
            blockList.append(CXCallDirectoryPhoneNumber.init(exactly: i)!)
        }
        for i in 14800000000...14809999999{
            blockList.append(CXCallDirectoryPhoneNumber.init(exactly: i)!)
        }*/
        // let blockedPhoneNumbers: [CXCallDirectoryPhoneNumber] = blockList
        // must be sequential list of blocked numbers
        for phoneNumber in blockList.sorted(by: <) {
            print("blocked number: \(phoneNumber)")
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
    }
    
    private func addIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [ 18775555555, 18885555555 ]
        let labels = [ "Telemarketer", "Local business" ]
        
        for (phoneNumber, label) in zip(phoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }
    
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("An error occurred while adding blocking phone numbers \(error)")
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occured while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }
    
}

extension CXCallDirectoryManager.EnabledStatus: CustomStringConvertible {
    
    public var description: String {
        switch self{
        case .disabled:
            return "disabled"
        case .enabled:
            return "enabled"
        case .unknown:
            return "unknown"
        }
    }
}
