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

/*
protocol SendDataToMainVCProtocol{
    func sendData(syncedDevices: [CBPeripheral], receivingVC: MainViewController)
}*/

class BeaconViewController: UIViewController{
    
    // MARK ADD CODE:  Consider adding a re-scan button, and calibrating power per device
    
    var mainVC: MainViewController!
    
    var cbPeripherals: [CBPeripheral] = appDelegate.cbPeripherals{
        didSet{
            beaconList.reloadAllComponents()
            if cbPeripherals.count == 1{
                uuID.text = cbPeripherals.last!.identifier.uuidString
            }
        }
    }
    var syncedDevices: [CBPeripheral] = appDelegate.syncedDevices{
        didSet{
            if syncedDevicesTableView != nil{
                syncedDevicesTableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var uuID: UITextField!
    
    @IBOutlet weak var beaconList: UIPickerView!
    
    @IBOutlet weak var syncedDevicesTableView: UITableView!
    
    @IBOutlet weak var addDeviceButton: UIButton!

    @IBAction func addDeviceButtonHit(_ sender: Any) {
        
        print("Transferring device from cbPeripherals to syncedDevices")
        let myIndex = beaconList.selectedRow(inComponent: 0)
        appDelegate.syncedDevices.append(appDelegate.cbPeripherals[myIndex])
        appDelegate.cbPeripherals.remove(at: myIndex)
        print("SyncedDevices \(appDelegate.syncedDevices.map({$0.name ?? $0.identifier.uuidString}))")

        self.syncedDevicesTableView.reloadData()

        // MARK ADD CODE:  PREVENT USER FROM ADDING DUPLICATE DEVICE
        
    }

    @IBAction func mainButtonHit(_ sender: Any) {
        print("mainHit")
            
    }
    
    func setupView(){
        uuID?.delegate = self
        uuID?.font = uuID.font!.withSize(UIFont.systemFontSize)
        addDeviceButton.layer.cornerRadius = 9
        addDeviceButton.layer.borderWidth = 1
        beaconList.delegate = self
        beaconList.dataSource = self
        beaconList.backgroundColor = UIColor.init(red: 255, green: 255, blue: 204)
        uuID.delegate = self
        uuID.textAlignment = .center
        syncedDevicesTableView.delegate = self
        syncedDevicesTableView.dataSource = self
        syncedDevicesTableView.backgroundColor = UIColor.init(red: 255, green: 255, blue: 204)
        print("Synced devices: \(syncedDevices)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // sendDataToMainVCDelegate = selfbhlp;gv
    }
    func isPending(state: CBPeripheralState)->Bool{
        switch state {
        case .connecting,.disconnecting:
            return true
        default:
            return false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Will move this functionality to the icon menu eventually
        self.dismiss(animated: true) {
            print("Seguing back...")
            
            if appDelegate.syncedDevices.count > 0 {
                var cbUUIDs: [CBUUID] = []
                for uuID in appDelegate.syncedDevices.map({$0.identifier}){
                    cbUUIDs.append(CBUUID(nsuuid: uuID))
                }
                print(cbUUIDs)
                appDelegate.duplicateDeviceCount = 0
                appDelegate.deviceManager.scanForPeripherals(withServices: nil, options: nil)
                //appDelegate.deviceManager.scanForPeripherals(withServices: cbUUIDs, options: nil)
                // maybe indicate multiple somehow on homescreen later
                self.mainVC.inRangeTextField.text = "Connecting to \(appDelegate.syncedDevices.last!.name ?? "unknown")"
            }
        }
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

        return CGFloat.init(250)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{

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

extension BeaconViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    
    // number of rows based on bluetooth devices synced to app
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return appDelegate.syncedDevices.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        // MARK ADD CODE: MAKE CELL TO REFLECT BLUETOOTH DEVICE ARRAY DATA
        if let syncedDeviceCell = tableView.dequeueReusableCell(withIdentifier: "syncedDeviceCell") as? SyncedDeviceCell{
            syncedDeviceCell.deviceName.text = appDelegate.syncedDevices[indexPath.row].name
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

/*
extension BeaconViewController: SendDataToMainVCProtocol{
    
    func sendData(syncedDevices: [CBPeripheral], receivingVC: MainViewController){
        print("Sending data back to main vc: \(syncedDevices)")

        receivingVC.syncedDevices = syncedDevices
        receivingVC.inRangeTextField.font = UIFont(name: "TimesNewRomanPSMT", size: 12.0)
        receivingVC.inRangeTextField.text = "Searching for \(syncedDevices.last?.name ?? "unknown")"
        // receivingVC.initializeCoreBluetoothManager()
        // receivingVC.deviceManager = cbCentralManager
        // removed above line to implement appDelegate
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
*/


