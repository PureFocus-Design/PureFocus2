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

// let appDelegate = UIApplication.shared.delegate as! AppDelegate

protocol SendDataToMainVCProtocol{
    func sendData(syncedDevices: [CBPeripheral], receivingVC: MainViewController)
}

class BeaconViewController: UIViewController{
    
    var cbCentralManager: CBCentralManager!
    var locationManager: CLLocationManager!
    var mainVC: MainViewController!
    var sendDataToMainVCDelegate: SendDataToMainVCProtocol!
    var duplicateDeviceCount: Int = 0
    
    // Checks for bluetooth devices that can connect
    internal var possiblePeripherals: [CBPeripheral] = []
    // connects and disconnects to test
    var cbPeripherals: [CBPeripheral] = []{
        didSet{
            beaconList.reloadAllComponents()
            if cbPeripherals.count == 1{
                uuID.text = cbPeripherals.last!.identifier.uuidString
            }
        }
    }
    // user activates from the tested devices
    var syncedDevices: [CBPeripheral] = []{
        didSet{
            if syncedDevicesTableView != nil{
                syncedDevicesTableView.reloadData()
            }
        }
        willSet{
            print("BeaconVC.syncedDevices.newValue: \(newValue)")
        }
    }
    
    @IBOutlet weak var uuID: UITextField!
    
    @IBOutlet weak var beaconList: UIPickerView!
    
    @IBOutlet weak var syncedDevicesTableView: UITableView!
    
    
    
    @IBOutlet weak var addDeviceButton: UIButton!

    @IBAction func addDeviceButtonHit(_ sender: Any) {
        
        print("Transferring device from cbPeripherals to syncedDevices")
        let myIndex = beaconList.selectedRow(inComponent: 0)
        syncedDevices.append(cbPeripherals[myIndex])
        
        // MARK ADD CODE:  PREVENT USER FROM ADDING DUPLICATE DEVICE
        
    }

    @IBAction func mainButtonHit(_ sender: Any) {
        print("mainHit")
            
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        uuID?.delegate = self
        uuID?.font = uuID.font!.withSize(UIFont.systemFontSize)
        addDeviceButton.layer.cornerRadius = 9
        addDeviceButton.layer.borderWidth = 1
        beaconList.delegate = self
        beaconList.dataSource = self
        beaconList.backgroundColor = UIColor.init(red: 255, green: 255, blue: 204)
        uuID.delegate = self
        uuID.textAlignment = .center
        cbCentralManager = CBCentralManager()
        cbCentralManager.delegate = self
        syncedDevicesTableView.delegate = self
        syncedDevicesTableView.dataSource = self
        syncedDevicesTableView.backgroundColor = UIColor.init(red: 255, green: 255, blue: 204)
        print("Synced devices: \(syncedDevices)")
        sendDataToMainVCDelegate = self
    }
    func isPending(state: CBPeripheralState)->Bool{
        switch state {
        case .connecting,.disconnecting:
            return true
        default:
            return false
        }
    }
    func waitForDevices(delayInSeconds: Double){
        var pendingDevices: [CBPeripheral] = []
        let allDevices: [CBPeripheral] = possiblePeripherals + cbPeripherals
        cbCentralManager.stopScan()
        
        for device in allDevices{
            if isPending(state: device.state){
                pendingDevices.append(device)
            }
        }
        for device in syncedDevices{
            if device.state == .disconnecting{
                pendingDevices.append(device)
            }
        }
        delay(bySeconds: delayInSeconds, dispatchLevel: .main) {
            for device in pendingDevices{
                if device.state == .connected{
                    self.cbCentralManager.cancelPeripheralConnection(device)
                }
            }
        }
        for device in pendingDevices{
            if device.state == .connected{
                print("need longer delay to disconnect devices")
            }
            cbCentralManager.delegate = nil
            print("Successfully cleared devices")
        }
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
        self.cbCentralManager.stopScan()
        sendDataToMainVCDelegate.sendData(syncedDevices: syncedDevices, receivingVC: self.mainVC)
        self.dismiss(animated: true) {
            print("Seguing back")
            
            /* avoid strong reference cycles
            self.sendDataToMainVCDelegate = nil // could make weak class var
            self.mainVC = nil*/
            // self.waitForDevices(delayInSeconds: 1.0)
        }
    }
    
    override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        super.unwind(for: unwindSegue, towardsViewController: subsequentVC)
        print("Unwinding from beacon")
        let mainVC = subsequentVC as! MainViewController
        mainVC.syncedDevices = syncedDevices
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("PrepareToSegue called")
        let mainVC = segue.destination as! MainViewController
        mainVC.syncedDevices = syncedDevices
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
        return CGFloat.init(250)
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
        let attributes = [ NSFontAttributeName: UIFont(name: "TimesNewRomanPSMT", size: 12.0)! ]
        var fancyName: NSAttributedString!
        if cbPeripherals.count > 0{
            if let name: String = cbPeripherals[row].name{
                fancyName = NSAttributedString.init(string: name, attributes: attributes)
                return fancyName
            }
        }
        fancyName = NSAttributedString.init(string: "unknown", attributes: attributes)
        return fancyName
        
    }// attributed title is favored if both methods are implemented
 /*
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView{
        
    }
 */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        if cbPeripherals.count > 0{
            self.uuID.text = cbPeripherals[row].identifier.uuidString
        }
    }
    
    // DATA SOURCE METHODS
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return cbPeripherals.count
    }
}

extension BeaconViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Inside delegate callback of Beacon.cbCentralManager.")
        switch central.state{
        case .poweredOn:
            print("centralManager powered on")
            cbCentralManager.scanForPeripherals(withServices: nil, options: nil)
            print("cbCentralManager.isScanning \(cbCentralManager.isScanning)")
        case .poweredOff:
            print("centralManager powered off")
        case .resetting:
            print("centralManager resetting")
        case .unauthorized:
            print("centralManager unauthorized")
            // ADD CODE TO DEMAND AUTH
        case .unknown:
            print("centralManager unknown")
        case .unsupported:
            print("centralManager unsupported")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // MARK ADD CODE:  Consider a rescanning button
        print("CB: Duplicate device count: \(duplicateDeviceCount)")
        if duplicateDeviceCount > 10 {  // exits after 10 duplicate names are found
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
        }
        
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Beacon.didConnect to: \(peripheral)")
        peripheral.delegate = self
        var isDuplicate = false
        for cbPeripheral in cbPeripherals{
            if peripheral.name == cbPeripheral.name{
                isDuplicate = true
            }
        }
        if !isDuplicate{
            cbPeripherals.append(peripheral)
            print("CB: cbPeripherals: \(cbPeripherals)")
        }
        // cancel connections because we are just testing
        central.cancelPeripheralConnection(peripheral)
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
        if let syncedDeviceCell = tableView.dequeueReusableCell(withIdentifier: "syncedDeviceCell") as? SyncedDeviceCell{
            syncedDeviceCell.deviceName.text = syncedDevices[indexPath.row].name
            return syncedDeviceCell
        }
        return SyncedDeviceCell()
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            syncedDevices.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
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
extension BeaconViewController: SendDataToMainVCProtocol{
    
    func sendData(syncedDevices: [CBPeripheral], receivingVC: MainViewController){
        print("Sending data back to main vc: \(syncedDevices)")

        receivingVC.syncedDevices = syncedDevices
        receivingVC.inRangeTextField.font = UIFont(name: "TimesNewRomanPSMT", size: 12.0)
        receivingVC.inRangeTextField.text = "Searching for \(syncedDevices.last?.name ?? "unknown")"
        // receivingVC.initializeCoreBluetoothManager()
        receivingVC.deviceManager = cbCentralManager
        print("syncedDevices \(syncedDevices)")
        for device in syncedDevices{
            receivingVC.deviceManager.connect(device, options: nil)
            receivingVC.deviceManager.delegate = receivingVC
            let connectedPeripherals = receivingVC.deviceManager.retrieveConnectedPeripherals(withServices: [CBUUID.init(nsuuid: device.identifier)])
            print("connectedPeripherals: \(connectedPeripherals)")
        }
        receivingVC.reloadInputViews()
    }
}



