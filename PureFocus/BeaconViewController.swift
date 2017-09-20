//
//  BeaconViewController.swift
//  PureFocus
//
//  Created by Ryan Dines on 8/18/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

class BeaconViewController: UIViewController {
    
    var cbCentralManager: CBCentralManager!
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var uuID: UITextField!
    
    @IBOutlet weak var majorTextfield: UITextField!
    
    @IBOutlet weak var minorTextField: UITextField!
    
    var beaconUUID: String!{
        didSet{
            print("beaconUUID: \(beaconUUID!)")
        }
    }
    /*
    var major: Int!{
        didSet{
            if major != nil{
                print("major: \(major!)")
            }
        }
    }
    var minor: Int!{
        didSet{
            if minor != nil {
                print("minor: \(minor!)")
            }
        }
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uuID.placeholder = beaconUUID
        majorTextfield.placeholder = "IDFK"
        minorTextField.placeholder = "REMOVE"
        uuID.delegate = self
        uuID.font = uuID.font!.withSize(UIFont.smallSystemFontSize)
        majorTextfield.textAlignment = .center
        minorTextField.textAlignment = .center
        majorTextfield.delegate = self
        minorTextField.delegate = self
        cbCentralManager = CBCentralManager()
        cbCentralManager.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true) {
            print("Seguing back")
        }
        /*
        if UIAccessibilityIsGuidedAccessEnabled(){
            print("Disabling SingleApp mode")
            UIAccessibilityRequestGuidedAccessSession(false){
                success in
                print("Request SingleApp mode turn off success: \(success)")
            }
        }*/
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mainVC = segue.destination as! MainViewController
        mainVC.beaconUUID = self.beaconUUID
        //mainVC.major = self.major
        //mainVC.minor = self.minor
    }

}
extension BeaconViewController: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        return true
    }// return NO to disallow editing.
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        
    }// became first responder
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        
        return true
    }// return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
    
    func textFieldDidEndEditing(_ textField: UITextField){
        if textField.accessibilityIdentifier == "uuID"{
            print("UUID done")
        }
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        return true
    }// return NO to not change text
    func textFieldShouldClear(_ textField: UITextField) -> Bool{
        // validate data before clearing
        return true
    }// called when clear button pressed. return NO to ignore (no notifications)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        // called when 'return' key pressed. return NO to ignore.
        // validate data before returning
        if textField.accessibilityIdentifier == "UUID"{
            beaconUUID = textField.text!
            print("Inside UUID")
        }
        /*
        if textField.accessibilityIdentifier == "Major"{
            major = Int(textField.text!)
            print("Inside Major")
        }
        if textField.accessibilityIdentifier == "Minor"{
            print("Inside Minor")
            minor = Int(textField.text!)
        }*/
        textField.resignFirstResponder()
        return true
    }
}
extension BeaconViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("Checking for beacons")
    }
}
extension BeaconViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Inside delegate callback of cbCentralManager.")
        switch central.state{
        case .poweredOn:
            print("centralManager powered on")
            cbCentralManager.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            print("centralManager powered off")
        case .resetting:
            print("centralManager resetting")
        case .unauthorized:
            print("centralManager unauthorized")
        case .unknown:
            print("centralManager unknown")
        case .unsupported:
            print("centralManager unsupported")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let advertisedName = advertisementData["kCBAdvDataLocalName"] as? String{
            if advertisedName.contains("ion"){
                print("Found ion beacon")
                print("peripheral \(peripheral)")
                beaconUUID = peripheral.identifier.uuidString
                uuID.text = beaconUUID
                print("advertisementData \(advertisementData)")
                print("RSSI \(RSSI)")
            }
            cbCentralManager.stopScan()
        }
    }
}
