//
//  WhiteList.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/25/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import UIKit
import CallKit
import Contacts

class WhiteListVC: UIViewController{
    
    // MARK NEW CODE:  SEND WHITELIST TO EXTENSION, CALLS BREAK SINGLE APP MODE
    
    var whitelist: [String:CXCallDirectoryPhoneNumber] = [:]
    var contactlist: [String:CXCallDirectoryPhoneNumber] = [:]
    var callDirManager = CXCallDirectoryManager.sharedInstance
    let defaults = UserDefaults(suiteName: "group.purefocus")!
    
    func reloadExtension(){
        if extensionIsValid(){
            callDirManager.reloadExtension(withIdentifier: "com.dimez.PureFocus.CallManager", completionHandler: { (error) in
                print("Reloading extension.")
                if let validError = error {
                    print("Error loading extension: \(validError)")
                }
            })
        }
    }
    
    func extensionIsValid() -> Bool {
        var extensionIsValid: Bool = false
        callDirManager.getEnabledStatusForExtension(withIdentifier: "com.dimez.PureFocus.CallManager") { (cXCallDirectoryManagerEnabledStatus) in
            switch cXCallDirectoryManagerEnabledStatus.0{
            case .disabled:
                // add code: present instructions modally
                print("App extension disabled, pop instructions on enabling.")
            case .unknown:
                print("Unknown state of extension")
            case .enabled:
                print("Extension is enabled.")
                extensionIsValid = true
            }
            if let validError = cXCallDirectoryManagerEnabledStatus.1{
                print("Error validating extension: \(validError)")
            }
        }
        return extensionIsValid
    }
    
    func getDigits(phone :String)->Int?{
        var digits = phone.components(separatedBy: "digits=").last!
        digits = digits.components(separatedBy: ">").first!
        if digits.contains("+"){
            digits.characters.removeFirst(1)
        }
        if digits.contains(";"){
            digits.characters.removeLast(5)
        }
        if digits.characters.count == 10{
            digits.characters.insert("1", at: digits.characters.startIndex)
        }
        if digits.characters.count < 10{
            return nil
        }
        return Int(digits)
    }
    
    func loadContacts(){
        let contactStore = CNContactStore()
        let keys = [CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNicknameKey, CNContactPhoneNumbersKey]
        let request1 = CNContactFetchRequest(keysToFetch: keys  as [CNKeyDescriptor])
        try! contactStore.enumerateContacts(with: request1) { (contact, error) in
            for phone in contact.phoneNumbers {
                if let validPhone = self.getDigits(phone: phone.value.description){
                    print("Phone: \(validPhone)")
                    
                    // MARK ADD CODE:  Pull names and make dictionary for whitelist
                    
                    // self.blockList.append(CXCallDirectoryPhoneNumber(validPhone))
                }
            }
        }
    }
    
    override func viewDidLoad(){
        /*
         
         MARK ADD CODE: ADD METHODS TO GROUP NUMBER AND WHITELIST
         
         defaults.set(false, forKey: "beaconInRange")
         defaults.synchronize()
         // loadContacts()
         defaults.set(blockList, forKey: "blockList")
         print(defaults.bool(forKey: "beaconInRange"))
         UIAccessibilityRequestGuidedAccessSession(true){
         success in
         print("Request guided access success: \(success)")
         }*/
        // defaults.set(false, forKey: "idfk")
    }
    
}
