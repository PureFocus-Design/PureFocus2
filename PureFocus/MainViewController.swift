//
//  ViewController.swift
//  SimpleButtonDemo
//
//  Created by Ryan Dines on 8/15/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit
// import CoreLocation
import Foundation
import Alamofire
import CoreBluetooth


class MainViewController: UIViewController{
    
    // Future implementation:  You could write an API call that checked how long the app has been running
    // and contacts someone if it's off.
    
    // Future refinement:  Consider weighted average vs straight average power rating
    
    // PROPERTIES
    
    // Networking and emergency calling
    
    let alamo = AlamoNetwork()
    var emergencyCall: String = "7274531901"  // change to 911 before release
    
    // Tracking Beacons (might remove isBlocking/isLocked and replace with AppState)
    // Currently, isBlocking indicates that the beacon is in range, isLocked indicates single app mode
    
    var isBlocking = false
    var isLocked: Bool = false
    
    // Could probably remove CoreLocation entirely if connecting to devices works
    
    // var locationManager: CLLocationManager!
    var deviceManager: CBCentralManager!
    let BRAND_IDENTIFIER = "com.purefocus"
    var syncedDevices: [CBPeripheral] = []{
        willSet{
            print("MainVC syncedDevices: \(newValue)")
        }
    }
    var deviceUUIDs: [CBUUID]{
        var deviceUUIDs: [CBUUID] = []
        for device in syncedDevices{
            deviceUUIDs.append(CBUUID.init(nsuuid: device.identifier))
        }
        return deviceUUIDs
    }
    
    /*{
        willSet{
            if newValue.count > 0{
                self.inRangeTextField.text = newValue.last!.name
                for device in newValue{
                    if deviceManager != nil && device.state == .disconnected{
                        // deviceManager asks to connect to synced device as soon as it's set from beaconVC
                        // connection wakes the app, API call to lock
                        // API call to unlock
                        // Measure RSSI avergae
                        // lock inApp for faster response time
                        deviceManager.connect(device, options: nil)
                    }
                }
            }
        }
    }*/
    /*{
        willSet{
            print("MainVC: syncedDevices newValue \(newValue)")
            if let validName = newValue.last?.name{
                self.inRangeTextField.text = validName
            }
            if newValue.count == 0{
                // stops when there's nothing to search for
                deviceManager.stopScan()
            }
        }
        didSet{
            if oldValue.count == 0{
                var services: [CBUUID] = []
                // could optimize for only 1
                for device in syncedDevices{
                    services.append(CBUUID(nsuuid: UUID.init(uuidString: device.identifier.uuidString)!))
                }
                deviceManager.scanForPeripherals(withServices: services, options: nil)
                print("scanning started")
            }
        }
    }*/
    /* replaced by synced devices
    var beaconRegions: [CLBeaconRegion]{
        var beaconRegions: [CLBeaconRegion] = []
        for beacon in syncedDevices{
            let beaconRegion = CLBeaconRegion.init(proximityUUID: beacon.identifier, identifier: beacon.name ?? BRAND_IDENTIFIER)
            beaconRegion.notifyOnEntry = true
            beaconRegion.notifyOnExit = true
            beaconRegion.notifyEntryStateOnDisplay = true
            beaconRegions.append(beaconRegion)
        }
        return beaconRegions
    }*/
    var lastFiveReadings: [Double] = []{
        willSet{
            print("NEW! Updating lastFiveReadings: \(newValue)")
        }
    }
    
    // Device setup
    
    var beaconViewController: BeaconViewController!
    // var locationTrackingAuthorized: Bool = false
    var bluetoothPeripheralAuthorized: Bool!
    
    var isLandscape: Bool{
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return true
        case .landscapeRight:
            return true
        default:
            return false
        }
    }
    var readingsAverage: Double{

        var total = 0.0
        lastFiveReadings.forEach { (reading) in
            total += reading
        }
        let returnValue = total/Double(lastFiveReadings.count)
        print("NEW! readingsAverage \(returnValue)")
        return returnValue
    }

    
    @IBOutlet weak var callBlockStatusSwitch: UISwitch!
    
    @IBOutlet weak var setupLabel: UILabel!
    
    @IBOutlet weak var beaconButton: UIButton!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var mainVCButton: UIButton!
    
    @IBOutlet weak var deviceVCButton: UIButton!
    
    @IBOutlet weak var allowVCButton: UIButton!
    
    @IBOutlet weak var SettingsVCButton: UIButton!
    
    @IBOutlet weak var iconView: UIView!
    
    @IBAction func callBackSwitchHit(_ sender: Any) {
        
        // Not used, probably will delete and move to settings
        
    }
    
    @IBOutlet weak var inRangeTextField: UITextField!
    
    @IBAction func emergencyCallHit(_ sender: Any) {
        print("Calling 911")
        
        // Mark add code
        
        if isLocked {
            alamo.singleAppModeLock(enable: false)
            isLocked = false
        }
        if UIAccessibilityIsGuidedAccessEnabled(){
            print("Disabling SingleApp mode")
            UIAccessibilityRequestGuidedAccessSession(false){
                success in
                print("Request SingleApp mode turn off success: \(success)")
            }
        }
        delay(bySeconds: 30, dispatchLevel: .background) {
            self.call911()
        }
    }
    
    func setupView(){
        beaconButton?.backgroundColor = UIColor.init(rgb: 0x228B22)
        beaconButton?.setTitle("+", for: .normal)
        beaconButton?.layer.cornerRadius = 9
        beaconButton?.layer.borderWidth = 1
        mainVCButton?.layer.cornerRadius = 9
        mainVCButton?.layer.borderWidth  = 1
        deviceVCButton?.layer.cornerRadius = 9
        deviceVCButton?.layer.borderWidth = 1
        allowVCButton?.layer.cornerRadius = 9
        allowVCButton?.layer.borderWidth = 1
        SettingsVCButton?.layer.cornerRadius = 9
        SettingsVCButton?.layer.borderWidth = 1
        iconView?.layer.cornerRadius = 9
        iconView?.layer.borderWidth = 1
        if let validBeacon = syncedDevices.last {
            inRangeTextField.textAlignment = .center
            inRangeTextField.text = "Searching for \(validBeacon.name ?? "unknown")"
        }else{
            inRangeTextField?.textAlignment = .center
            inRangeTextField?.placeholder = "Tap + button to add beacon"
        }
        inRangeTextField?.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainVC.viewDidLoad")
        setupView()
        // if allowed to connect to a peripheral in the background
        initializeCoreBluetoothManager()
        // else segue to auth page
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isLandscape{
            logoImage?.isHidden = true
        }else{
            logoImage?.isHidden = false
        }
    }
    /*
    override func viewWillLayoutSubviews() {

        super.viewWillLayoutSubviews()
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    func rangeBeacons(){
        for region in beaconRegions{
            print("Loading \(region) into locationManager for ranging")
            locationManager.startRangingBeacons(in: region)
        }
    }*/
    
    func initializeCoreBluetoothManager(){
        deviceManager = CBCentralManager()
        deviceManager.delegate = self
        // MARK ADD CODE: AUTH BLUETOOTH
        bluetoothPeripheralAuthorized = true
    }
    /*
    func initializeLocationManager(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true

    }*/
    
    func call911(){
        if let url = URL(string: "tel://\(emergencyCall)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Segueing")
        let beaconViewController = segue.destination as! BeaconViewController
        beaconViewController.mainVC = self
    }
    @IBAction func unwindToMain(segue:UIStoryboardSegue) { }
    
    /*  MARK ADD CODE: REPLACE WITH CHECK FOR BLUETOOTH AUTH
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedAlways:
            locationTrackingAuthorized = true
        default:
            return
        }
    }*/
    
   // func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    
    // Ranging is like discovering, when we're close enough we want to connect
    /*
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if syncedDevices.count > 0 && bluetoothPeripheralAuthorized {
            
            if readingsAverage > 4.20{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                inRangeTextField.text = "Beacon out of range"
                
                if isLocked{
                    
                    alamo.singleAppModeLock(enable: false)
                    isLocked = false
                    if self.isBlocking == true{
                        if UIAccessibilityIsGuidedAccessEnabled(){
                            print("Disabling GuidedAccess")
                            UIAccessibilityRequestGuidedAccessSession(false){
                                success in
                                print("Request single app mode off success: \(success)")
                                self.isBlocking = false
                            }
                        }
                    }
                    
                }else if readingsAverage > 0.0{
                    inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                    inRangeTextField.textAlignment = .center
                    inRangeTextField.text = "Beacon in range"
                    if !isLocked{
                        alamo.singleAppModeLock(enable: true)
                        isLocked = true
                    }
                    if self.isBlocking == false{
                        alamo.singleAppModeLock(enable: true)
                        // MARK ADD CODE:  ADD COMPLETION HANDLER TO ABOVE FUNCTION
                        self.isBlocking = true
                        if !UIAccessibilityIsGuidedAccessEnabled(){
                            print("Enabling GuidedAccess")
                            UIAccessibilityRequestGuidedAccessSession(true){
                            success in
                                print("Request single app mode on success: \(success)")
                            }
                         }
                    }
                }
                // let beaconAccuracy = beacons.last!.accuracy
                
                if lastFiveReadings.count == 5{
                    // remove old reading if full
                    lastFiveReadings.remove(at: 0)
                }
                lastFiveReadings.append(Double(RSSI))

            } else {
                if syncedDevices.count > 0{
                    self.inRangeTextField.text = syncedDevices.last!.identifier.uuidString
                }
            }
        }
    }*/
}

    
extension UIColor {
        
        convenience init(red: Int, green: Int, blue: Int) {
            assert(red >= 0 && red <= 255, "Invalid red component")
            assert(green >= 0 && green <= 255, "Invalid green component")
            assert(blue >= 0 && blue <= 255, "Invalid blue component")
            
            self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
        }
        
        convenience init(rgb: Int) {
            self.init(
                red: (rgb >> 16) & 0xFF,
                green: (rgb >> 8) & 0xFF,
                blue: rgb & 0xFF
            )
        }
    }
extension UIViewController{
    
    public func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .main, closure: @escaping () -> Void) {
        let dispatchTime = DispatchTime.now() + seconds
        dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
    }
    
    public enum DispatchLevel {
        case main, userInteractive, userInitiated, utility, background
        var dispatchQueue: DispatchQueue {
            switch self {
            case .main:                 return DispatchQueue.main
            case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
            case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
            case .utility:              return DispatchQueue.global(qos: .utility)
            case .background:           return DispatchQueue.global(qos: .background)
            }
        }
    }
}

extension MainViewController: CBCentralManagerDelegate, CBPeripheralDelegate{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print("Inside delegate callback of Main.cbCentralManager.")
        switch central.state{
        case .poweredOn:
            print("centralManager powered on")
            if !central.isScanning{
                print("deviceUUIDs: \(deviceUUIDs)")
                central.scanForPeripherals(withServices: nil, options: nil)
                print("Main.cbCentralManager.isScanning \(central.isScanning)")
            }
            /*
            if syncedDevices.count > 0 {
                var services: [CBUUID] = []
                for device in syncedDevices{
                    services.append(CBUUID(nsuuid: UUID.init(uuidString: device.identifier.uuidString)!))
                }
                deviceManager.scanForPeripherals(withServices: services, options: nil)
            }*/
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
        print("Main.didDiscover device \(peripheral.name ?? "unknown"), .\(peripheral.state), \(RSSI)")
        for device in syncedDevices{
            print("Interested in this: \(device.name ?? "unknown"), \(device.state)")
            if device.state == .disconnected{
                deviceManager.connect(device, options: nil)
            }
            if peripheral.state == .disconnected{
                deviceManager.connect(device, options: nil)
            }
        }
        if peripheral.state == .connected{
            print("and it's connected")
            // print("didDiscover active device \(peripheral.name ?? "unknown"), .\(peripheral.state)")
        }
        
        /*
        for device in syncedDevices{
            if peripheral.identifier == device.identifier{
                print("DISCOVERED SYNCED DEVICE: ")
                print("uuid \(peripheral.identifier)")
                print("RSSI: \(RSSI)")
                switch  peripheral.state {
                case .connected:
                    if lastFiveReadings.count == 5{
                        // remove old reading if full
                        lastFiveReadings.remove(at: 0)
                    }
                    lastFiveReadings.append(Double(RSSI))
                    return
                case .connecting,.disconnecting:
                    return
                case .disconnected:
                    central.connect(peripheral, options: nil)
                }
            }
        }*/
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Main.didConnect to: \(peripheral)")
        // connection wakes the app, API call to lock
        
        // below may be redundent
        peripheral.delegate = self
        var isValid = false
        for syncedDevice in syncedDevices{
            // checks by iterating over synced device array to verify it has a matching name
            if peripheral.name == syncedDevice.name{
                isValid = true
                // locks upon connection
                print("Locking down phone via API call")
                lockdownPhone(auto: false)
                // then unlock, then range beacons and enter autonomously
            }
        }
        // above may be redundant, since we only ask to connect to devices in our synced device array
        
        // cancel connections not related to ours (might need exemption for bluetooth headphones)
        if !isValid{
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func lockdownPhone(auto: Bool){
        inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
        inRangeTextField.textAlignment = .center
        inRangeTextField.text = "Beacon in range"
        if !auto{
            if !isLocked{
                alamo.singleAppModeLock(enable: true)
                isLocked = true
            }
        }else{
            // autonomous method
            if self.isBlocking == false{
                // MARK ADD CODE:  ADD COMPLETION HANDLER TO ABOVE FUNCTION
                if !UIAccessibilityIsGuidedAccessEnabled(){
                    print("Enabling GuidedAccess")
                    UIAccessibilityRequestGuidedAccessSession(true){
                        success in
                        print("Request single app mode on success: \(success)")
                        self.isBlocking = true
                    }
                }
            }
        }
    }
    
    /*
    func centralManagerDidUpdateState(_ central: CBCentralManager){
     

    }*/
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]){
        print("centralManager.willRestoreState: \(dict)")
        // MARK TO DO: MOVE centralManager to appDelegate
        
        // First method invoked when your app is relaunched the background to complete Bluetooth-related task
        
        // Use this method to synchronize your app's state with the state of the Bluetooth system
        
        // dict = A dictionary containing information about central</i> that was preserved
        
        // CBCentralManagerRestoredStatePeripheralsKey: [CBPeripheral]
        // CBCentralManagerRestoredStateScanServicesKey:  [UUID]
        // CBCentralManagerRestoredStateScanOptionsKey: Dict of the scannnning options
        
    }
    
    // Callback methods to communicate with bluetooth device
    
}






