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
    
    @IBOutlet weak var statusTextfield: UITextField!
    
    @IBOutlet weak var beaconList: UIPickerView!
    
    /*
    var beaconUUID: String!{
        didSet{
            print("beaconUUID: \(beaconUUID!)")
        }
    }*/
    
    var bluetoothDevices: [BluetoothDevice] = []
    
    var syncedDevices: [BluetoothDevice] {
        var syncedDevices: [BluetoothDevice] = []
        for device in bluetoothDevices{
            if device.bluetoothState == .synced{
                syncedDevices.append(device)
            }
        }
        return syncedDevices
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let validUUID = syncedDevices.last {
             uuID.placeholder = validUUID.uuID.uuidString
        }else{
            uuID?.placeholder = "Tap to enter manually"
        }
        uuID?.delegate = self
        uuID?.font = uuID.font!.withSize(UIFont.smallSystemFontSize)
        statusTextfield?.textAlignment = .center
        statusTextfield?.delegate = self
        beaconList?.delegate = self
        beaconList?.dataSource = self
        uuID.delegate = self
        uuID.font = uuID.font!.withSize(UIFont.smallSystemFontSize)
        statusTextfield.textAlignment = .center
        uuID.textAlignment = .center
        cbCentralManager = CBCentralManager()
        cbCentralManager.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // MARK ADD CODE:  ADD CODE TO REMOVE PROFILE IF LOCKED IN SINGLE APP MODE
        
        if UIAccessibilityIsGuidedAccessEnabled(){
            print("Disabling SingleApp mode")
            UIAccessibilityRequestGuidedAccessSession(false){
                success in
                print("Request SingleApp mode turn off success: \(success)")
            }
        }
        self.dismiss(animated: true) {
            print("Seguing back")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mainVC = segue.destination as! MainViewController
        mainVC.bluetoothDevices = self.bluetoothDevices
        // mainVC.beaconUUID = self.beaconUUID
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
            if let syncedDevice = syncedDevices.last{
                textField.text! = syncedDevice.uuID.uuidString
            }
        }
        textField.resignFirstResponder()
        return true
    }
}

extension BeaconViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    
    
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        print("widthForComponent: \(component)")
        return CGFloat.init(200)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{
        print("rowHeightForComponent: \(component)")
        return CGFloat.init(50)
    }
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        print("titleForRow: \(row)")
        
        // Dynamically fill titles with array of possible beacons
        return "Beacon title"
        
    }
    /*
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?{
        print("attributedTitleForRow: \(row)")
    }// attributed title is favored if both methods are implemented
 
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView{
        
    }
 */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        print("didSelectRow: \(row)")
    }
    
    // DATA SOURCE METHODS
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        print("numberOfComponents \(pickerView)")
        return 1
    }
    
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return 1
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
                bluetoothDevices.append(BluetoothDevice.init(uuID: peripheral.identifier.uuidString))
                print("advertisementData \(advertisementData)")
                print("RSSI \(RSSI)")
            }
            cbCentralManager.stopScan()
        }
    }
}
