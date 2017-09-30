//
//  Alamo.swift
//  PureFocus
//
//  Created by Ryan Dines on 8/22/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import Alamofire

class AlamoNetwork{
    
    // Future implementation:  You could write an API call that checked how long the app has been running
    // and contacts someone if it's off.
    
    func makeXMLHeaders()->String{
        
        let xmlheader1 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        let xmlheader2 = "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
        let xmlheader3 = "<plist version=\"1.0\">"
        
        return xmlheader1+xmlheader2+xmlheader3
    }
    
    func clientCheckIn(){
        
    }
    
    func singleAppModeLock(enable: Bool){
        print("Calling single app mode.")
        let headers = ["Content-Type":"application/x-www-form-urlencoded",
                       "Authorization":"Basic alBSaGxXMWdCT3o5cEtBaGxRWm01NHBCcHUzbmdhSTJaeDJOV0NqQTd1Qkc2N0daWXlxSDNMbHRRalF5Ukl5Qzo="]
        if enable{
            print("Sending API call to lock device.")
            
            // Ryan's URL group, comment out and and uncomment yours
            let assignProfileToGroup = "https://a.simplemdm.com/api/v1/custom_configuration_profiles/1240/device_groups/32489"
            
            // Kelly and Joe, switch this commented out link with the one above.  This thing is hard-coded for now.
            //  let assignProfileToGroup = "https://a.simplemdm.com/api/v1/custom_configuration_profiles/1241/device_groups/103140"
            
            let req = Alamofire.request(assignProfileToGroup,
                                        method: .post, parameters: [:],
                                        encoding: "", headers: headers)
            print(req)
        }else{
            
            // Ryan's URL group, comment out and uncomment yours
            let removeProfile = "https://a.simplemdm.com/api/v1/custom_configuration_profiles/1241/device_groups/32489"
            
            // Kelly and Joe, switch this commented out link with the one above.  This thing is hard-coded for now.
            // let removeProfile = "https://a.simplemdm.com/api/v1/custom_configuration_profiles/1241/device_groups/103140"
            
            let req = Alamofire.request(removeProfile,
                                        method: .delete, parameters: [:],
                                        encoding: "", headers: headers)
            print("Sending API call to unlock device.")
            print(req)
        }
    }
    
    
}
extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
    
}





