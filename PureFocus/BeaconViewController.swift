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

protocol SendDataProtocol: class {
    func sendData(syncedDevices: [CBPeripheral])
}

class BeaconViewController: UIViewController {
    
    var cbCentralManager: CBCentralManager!
    var locationManager: CLLocationManager!
    var duplicateDeviceCount: Int = 0
    weak var delegate: SendDataProtocol?
    
    // Checks for bluetooth devices that can connect
    internal var possiblePeripherals: [CBPeripheral] = []
    // connects and disconnects to test
    var cbPeripherals: [CBPeripheral] = []{
        didSet{
            beaconList.reloadAllComponents()
        }
    }
    // user activates from the tested devices
    var syncedDevices: [CBPeripheral] = []
    
    @IBOutlet weak var uuID: UITextField!
    
    @IBOutlet weak var statusTextfield: UITextField!
    
    @IBOutlet weak var beaconList: UIPickerView!
    
    @IBOutlet weak var syncedDevicesTableView: UITableView!
    
    @IBAction func addDeviceButtonHit(_ sender: Any) {
        
        print("Adding devices")
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if let validUUID = syncedDevices.last {
             uuID.placeholder = validUUID.identifier.uuidString
        }else{
            uuID?.placeholder = "Tap to enter manually"
        }
        uuID?.delegate = self
        uuID?.font = uuID.font!.withSize(UIFont.buttonFontSize)
        statusTextfield?.textAlignment = .center
        statusTextfield?.delegate = self
        beaconList?.delegate = self
        beaconList?.dataSource = self
        uuID.delegate = self
        statusTextfield.textAlignment = .center
        uuID.textAlignment = .center
        cbCentralManager = CBCentralManager()
        cbCentralManager.delegate = self
        delegate = self
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
        delegate?.sendData(syncedDevices: syncedDevices)
        self.dismiss(animated: true) {
            print("Seguing back")
        }
    }
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Segue called")
        let mainVC = segue.destination as! MainViewController
        print("MainVC: \(cbPeripherals)")
        mainVC.cbPeripherals = self.cbPeripherals
    }*/

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
                textField.text! = syncedDevice.identifier.uuidString
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
    /*
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        print("titleForRow: \(row)")
        
        // Dynamically fill titles with array of possible beacons
        return cbPeripherals[row].name
    }*/
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?{
        
        let name: String = cbPeripherals[row].name!
        let attributes = [ NSFontAttributeName: UIFont(name: "TimesNewRomanPSMT", size: 8.0)! ]
        let fancyName = NSAttributedString.init(string: name, attributes: attributes)
        print("attributedTitleForRow: \(fancyName)")
        return fancyName
    }// attributed title is favored if both methods are implemented
 /*
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
        return cbPeripherals.count
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
        // MARK ADD CODE:  Consider a rescanning button
        print("CB: Duplicate device count: \(duplicateDeviceCount)")
        if duplicateDeviceCount > 10 {  // exits after 3 duplicate names are found
            print("Stopping scan")
            self.cbCentralManager.stopScan()
            print("Is anyone scanning?: \(cbCentralManager.isScanning)")
            print("CB: possiblePeripherals: \(possiblePeripherals)")
            print("CB: Synced devices: \(syncedDevices)")
            print("CB: cbPeripherals: \(cbPeripherals)")
            for cbPeripheral in cbPeripherals{
                if cbPeripheral.state == .connected{
                    // cbPeripherals is for testing connections, should not be connected
                    central.cancelPeripheralConnection(peripheral)
                }
            }
            return
        }
        print("DISCOVERED DEVICE: ")
        print("uuid \(peripheral.identifier)")
        // let bluetoothDevice = BluetoothDevice(uuID: peripheral.identifier.uuidString)
        print("state: \(peripheral.state)")
        print("advertisement Data: \(advertisementData)")
        var isDuplicate = false
        if let connectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool{
            print("connectable: \(connectable)")
            if connectable{
                print("Attempting connection.")
                for possiblePeripheral in possiblePeripherals{
                    if peripheral.name == possiblePeripheral.name{
                        isDuplicate = true
                    }
                }
                if isDuplicate{
                    duplicateDeviceCount += 1
                }else{
                    self.possiblePeripherals.append(peripheral)
                }
                print("CB: possiblePeripherals: \(possiblePeripherals)")
                central.connect(peripheral, options: nil)
            }
        }
        if let advertisedName = advertisementData["kCBAdvDataLocalName"] as? String{
            print("advertisedName: \(advertisedName)")
            print("Checking uniqueness...")
            for device in cbPeripherals{
                if advertisedName == device.name{
                    // checks for uniqueness
                    duplicateDeviceCount += 1
                    print("duplicate found, total: \(duplicateDeviceCount)")
                    return
                }
            }
            print("DEVICE IS UNIQUE")

            // let bluetoothDevice = BluetoothDevice(uuID: peripheral.identifier.uuidString)
            // bluetoothDevice.name = advertisedName
            // must have name, that's how we check uniqueness
        }
        
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect to: \(peripheral)")
        peripheral.delegate = self
        var isDuplicate = false
        var isValid = false
        for cbPeripheral in cbPeripherals{
            if peripheral.name == cbPeripheral.name{
                isDuplicate = true
            }
        }
        if !isDuplicate{
            cbPeripherals.append(peripheral)
            print("CB: cbPeripherals: \(cbPeripherals)")
        }
        for syncedDevice in syncedDevices{
            if peripheral.name == syncedDevice.name{
                isValid = true
            }
        }
        // cancel connections that we were just testing
        if !isValid{
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
}

extension BeaconViewController: UITableViewDelegate, UITableViewDataSource{
    
    // number of rows based on bluetooth devices synced to app
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return syncedDevices.count
    }
    
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        // MARK ADD CODE: MAKE CELL TO REFLECT BLUETOOTH DEVICE ARRAY DATA
        let cell = UITableViewCell.init(style: UITableViewCellStyle.value1, reuseIdentifier: "syncedBeacon")
        
        return cell
    }
}
extension CBPeripheralState: CustomStringConvertible{
    public var description: String{
        switch self {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .disconnected:
            return "disconnected"
        case .disconnecting:
            return "disconnecting"
        }
    }
}
extension BeaconViewController: CBPeripheralDelegate{
    
    // Callback methods to communicate with bluetooth device
    
}
