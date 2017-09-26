//
//  WhiteList.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/25/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import UIKit

class WhiteListVC: UIViewcotroller{
    
    // MARK NEW CODE:  SEND WHITELIST TO EXTENSION, CALLS BREAK SINGLE APP MODE
    
    var whitelist: [String:CXCallDirectoryPhoneNumber] = [:]
    var contactlist: [String:CXCallDirectoryPhoneNumber] = [:]
    
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
