//
//  AppDelegate.swift
//  PureFocus
//
//  Created by Ryan Dines on 8/18/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // PROPERTIES:

    var window: UIWindow?
    var appState: AppState!
    var alamo = AlamoNetwork()
    
    // COREBLUETOOTH PROPERTIES (INSIDE OF APPDELEGATE TO OPTIMIZE WAKEUP)
    
    let BRAND_IDENTIFIER = "com.purefocus"
    var deviceManager: CBCentralManager!
    var bluetoothPeripheralAuthorized: Bool!
    // found when discovering any bluetooth for the first time
    internal var possiblePeripherals: [CBPeripheral] = []
    // tracks the number of repeat devices found and stops after a while
    var duplicateDeviceCount: Int = 0
    // found by testing connection to device
    var cbPeripherals: [CBPeripheral] = []{
        willSet{
            print("cbPeripherals: \(cbPeripherals)")
        }
    }
    // installed by user hitting button
    var syncedDevices: [CBPeripheral] = []
    var services: [CBUUID] {
        var myServices: [CBUUID] = []
        for device in syncedDevices{
            
            myServices.append(CBUUID(nsuuid: device.identifier))
        }
        
        return myServices.map {CBUUID(nsuuid: UUID.init(uuidString: $0.uuidString)!)}
    }
    var deviceUUIDs: [CBUUID]{
        var deviceUUIDs: [CBUUID] = []
        for device in syncedDevices{
            deviceUUIDs.append(CBUUID.init(nsuuid: device.identifier))
        }
        return deviceUUIDs
    }

    
    // SINGLE APP / GUIDED ACCESS PROPERTIES
    
    var isLocked: Bool!   // Single App
    var isBlocking: Bool! // Guided Access
    
    // TO DO:  ADD SAVE/LOAD CODE FROM PERSITENT STORE
    
    // CUSTOM METHODS
    
    func initializeCoreBluetoothManager(){
        deviceManager = CBCentralManager()
        deviceManager.delegate = self
    }
    
    // STANDARD METHODS

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Initialize if nil after application launch.
        if appState == nil{
            // foreground
            appState = AppState(internalAppState: .foreground, singleAppModeState: .unlocked)
        }else{
            appState.internalAppState = .foreground
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if appState == nil{
            // foreground
            appState.internalAppState = .background
        }
        // MARK ADD CODE: AUTH BLUETOOTH
        bluetoothPeripheralAuthorized = true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        appState.internalAppState = .background
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        appState.internalAppState = .foreground
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // returns from phone call
        appState.internalAppState = .foreground
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        appState.internalAppState = .terminated
    }
}
extension AppDelegate: CBCentralManagerDelegate, CBPeripheralDelegate{
    
    // BEACON VC FUNCTIONALITY
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Inside delegate callback of Beacon.cbCentralManager.")
        switch central.state{
        case .poweredOn:
            print("centralManager powered on")
            deviceManager.scanForPeripherals(withServices: nil, options: nil)
            print("cbCentralManager.isScanning \(deviceManager.isScanning)")
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
        
        
        // MainVC Implements
        
        
        print("Inside delegate callback of Main.cbCentralManager.")
        switch central.state{
        case .poweredOn:
            if !central.isScanning{
                var scanMethod = ""
                if syncedDevices.count > 0 {
                    scanMethod = "specific devices"
                    deviceManager.scanForPeripherals(withServices: services, options: nil)
                }else{
                    // if beaconVC is active, scan for everything
                    // if mainVC is active, scan for synced devices
                    central.scanForPeripherals(withServices: nil, options: nil)
                    scanMethod = "everything"
                }
                print("centralManager powered on and started scanning (\(central.isScanning)) for \(scanMethod)")
                print("deviceUUIDs: \(deviceUUIDs)")

            }
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
        
        // BeaconVC code
        print("CB: Duplicate device count: \(duplicateDeviceCount)")
        if duplicateDeviceCount > 10 {  // exits after 10 duplicate names are found
            print("Stopping scan")
            self.deviceManager.stopScan()
            print("Is anyone scanning?: \(deviceManager.isScanning)")
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
    
        // OLD MAIN VC DISCOVERY, MERGE SOON

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
        // OLD CORE LOCATION CODE, WE WANT SIMILAR FUNCTIONALITY
        
        var lastFiveReadings: [Double] = []{
            willSet{
                print("Updating lastFiveReadings: \(newValue)")
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
        }
        

        
        if syncedDevices.count > 0 && bluetoothPeripheralAuthorized {
            
            if readingsAverage > 4.20{
 
                //  Send messgae to mainVC: "Beacon out of range"
                
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
                    // Send message to mainVC: "Beacon in range"
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

                if lastFiveReadings.count == 5{
                    // remove old reading if full
                    lastFiveReadings.remove(at: 0)
                }
                lastFiveReadings.append(Double(RSSI))
                
            } else {
                if syncedDevices.count > 0{
                    // send "hit plus to add beacon notice to main.textfield
                }
            }
        }

        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Main.didConnect to: \(peripheral)")
        // connection wakes the app, API call to lock
        
        // below may be redundent
        for syncedDevice in syncedDevices{
            // checks by iterating over synced device array to verify it has a matching name
            if peripheral.name == syncedDevice.name{
                // locks upon connection
                print("Locking down phone via API call")
                lockdownPhone(auto: false)
                // then unlock, then range beacons and enter autonomously
            }
        }
        // above may be redundant, since we only ask to connect to devices in our synced device array
        
        // BEACON VC CODE FOLLOWS, WILL HAVE TO COMBINE THE TWO
        
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
            // cancel connection because we are just testing
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func lockdownPhone(auto: Bool){
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
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]){
        print("Chaconas: \(dict)")
        for key in dict.keys{
            print("\(key): \(dict[key]!)")
        }
        
        // First method invoked when your app is relaunched the background to complete Bluetooth-related task
        // Use this method to synchronize your app's state with the state of the Bluetooth system
        // dict = A dictionary containing information about central</i> that was preserved.  Keys to dict:
        
        // CBCentralManagerRestoredStatePeripheralsKey: [CBPeripheral]
        // CBCentralManagerRestoredStateScanServicesKey:  [UUID]
        // CBCentralManagerRestoredStateScanOptionsKey: Dict of the scannnning options
        
    }
}



