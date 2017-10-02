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
    
    // BIG IDEA: STATE OF APP (appState) DISPLAYED IN INRANGETEXTFIELD
    
    
    // APP TERMINATED CONNECTS TO ANY POWER, WAKES, DISCONNECTS, BEGINS RANGING
    
    // CONNECTING HAPPENS / DISCONNECTING FOLLOWS IMMEDIATELY
    
    // CONNECTING HAS NO CONTROL OVER THE STATE
    
    
    
    
    // OVERALL APP FLOW TO ACCOMPLISH LOCKDOWN OF PHONE:
    
    // connects to device if in right range of power
    
    // profile installs via API call to enter single app mode
    
    // profile uninstalls via API call to leave single app mode after 5 minutes
    
    // query connected device for proper range every second or so
    
    // app continues to lock in and out by autonomous guided access after 5 minutes  (fallsback to single app if unsuccessful)
    
    // Completely out of range of device or termination of app leads to single app method (default)
    
    // PROPERTIES:

    var window: UIWindow?
    var navVC: UINavigationController!
    var appState: AppState!
    var mainVC: MainViewController!
    var beaconVC: BeaconViewController!
    
    var alamo = AlamoNetwork()
    
    // COREBLUETOOTH PROPERTIES (INSIDE OF APPDELEGATE TO OPTIMIZE WAKEUP)
    
    let BRAND_IDENTIFIER = "com.purefocus"
    var deviceManager: CBCentralManager!

    /*
    var connectingRSSI: NSNumber!{
        willSet{
            print("Connecting RSSI: \(newValue)")
        }
    }*/
    var deviceRSSIs: [CBPeripheral:NSNumber] = [:]
    // found when discovering any bluetooth for the first time
    internal var possiblePeripherals: [CBPeripheral] = []
    // tracks the number of repeat devices found and stops after a while
    var duplicateDeviceCount: Int = 0{
        willSet{
            print("duplicateDeviceCount: \(newValue)")
        }
    }
    // found by testing connection to device
    var cbPeripherals: [CBPeripheral] = []
    // installed by user hitting button
    var syncedDevices: [CBPeripheral] = []
    
    // SINGLE APP / GUIDED ACCESS PROPERTIES
    
    var isLocked: Bool = false   // Single App
    var isBlocking: Bool = false // Guided Access
    
    
    // TO DO:  ADD SAVE/LOAD CODE FROM PERSITENT STORE
    
    func lockPhone(state: AppState){
        print("Locking phone, \(state.internalAppState)")
        switch appState.internalAppState{
        case AppState.AppState.foreground:
            //var successfulGuidedAccess: Bool = false
            if self.isBlocking == false{
                // Tries to block with in app method first, falls back to API call
                
                if !UIAccessibilityIsGuidedAccessEnabled(){
                    print("Enabling GuidedAccess")
                    UIAccessibilityRequestGuidedAccessSession(true){
                        success in
                        print("Request guided access mode on success: \(success)")
                        if success{
                            self.isBlocking = true
                        }else{
                            self.isBlocking = false
                            // fall back to API method if other one doesn't work
                            self.alamo.singleAppModeLock(enable: true)
                            print("Locking via api instead.")
                            self.isLocked = true
                        }
                    }
                }
            }
        default:
            if !isLocked{
                alamo.singleAppModeLock(enable: true)
                isLocked = true
            }
        }
    }
    func unlockPhone(state: AppState){
        print("Unlocking phone, \(state.internalAppState)")
        switch appState.internalAppState{
        case AppState.AppState.foreground:
            if self.isBlocking == true{
                // Tries to unlock with in app method first, falls back to API call
                if !UIAccessibilityIsGuidedAccessEnabled(){
                    print("Disabling GuidedAccess")
                    UIAccessibilityRequestGuidedAccessSession(false){
                        success in
                        print("Request guided access mode off success: \(success)")
                        if success{
                            self.isBlocking = false
                        }else{
                            // fallback method
                            self.alamo.singleAppModeLock(enable: false)
                            self.isLocked = false
                        }
                    }
                }
            }
            if isLocked {
                alamo.singleAppModeLock(enable: false)
                isLocked = false
            }
        default:
            if isLocked{
                alamo.singleAppModeLock(enable: false)
                isLocked = false
            }
        }
    }
    
    // STANDARD METHODS

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Initialize if nil after application launch.
        guard let validWindow = window else {return true}
        guard let validNavVC = validWindow.rootViewController as? UINavigationController else {return true}
        for vc in validNavVC.childViewControllers{
            print("Found validNavVC's child: \(vc)")
            
        }
        
        if appState == nil{
            // foreground
            appState = AppState(internalAppState: .foreground, singleAppModeState: .unlocked,
                                activeViewController: .main)
        }else{
            appState.internalAppState = .foreground
        }
        deviceManager = CBCentralManager()
        deviceManager.delegate = self
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if appState == nil{
            // foreground
            appState.internalAppState = .background
        }
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
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]){
        print("willRestoreState: \(dict)")
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
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        

        switch central.state{
        case .poweredOn:
            if !central.isScanning{
                central.scanForPeripherals(withServices: nil, options: nil)
                print("CentralManager powered on and started scanning.")
            }
        case .poweredOff:
            print("centralManager powered off")
        case .resetting:
            print("centralManager resetting")
        case .unauthorized:
            // ADD CODE TO DEMAND AUTH
            print("centralManager unauthorized")
        case .unknown:
            print("centralManager unknown")
        case .unsupported:
            print("centralManager unsupported")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Convenience printing of known power values
        var rssi: String {
            if RSSI.description == "127" {
                return "unknown"
            }else{
                return RSSI.description
            }
        }
        print("Discovered device \(peripheral.id), \(peripheral.state), power: \(rssi)")
        if syncedDevices.contains(peripheral) {
            switch peripheral.state {
            case .disconnected:
                peripheral.delegate = self
                // NEW CODE
                if Int(deviceRSSIs[peripheral]!) < -90 {
                    if !isBlocking || !isLocked {
                        lockPhone(state: appState)
                        // connects to wake up
                        deviceManager.connect(peripheral, options: nil)
                    }
                    print("Found device in range")
                }
                if Int(deviceRSSIs[peripheral]!) >= -90 {
                    if isLocked || isBlocking {
                        print("Device out of range")
                        unlockPhone(state: appState)
                    }
                }
                
            default:
                print("Found \(peripheral.id) \(peripheral.state)")
            }
            
        }
        
            
        self.deviceRSSIs[peripheral] = RSSI
        print("advertisement Data: \(advertisementData)")
        /*  MARK ADD CODE, MAKE WAY TO BREAK BASED ON WHICH VIEW CONTROLLER IS IN VIEW
         
        // Check for too many duplicates first, also need to include 10 second timeout for 0 devices left case

        if duplicateDeviceCount > 10 {  // exits after 10 duplicate names are found
            print("Stopping scan")
            self.deviceManager.stopScan()
            possiblePeripherals = []
            print("Is anyone scanning?: \(deviceManager.isScanning), final results:")
            print("possiblePeripherals: \(possiblePeripherals.map({$0.id}))")
            print("cbPeripherals: \(cbPeripherals.map({$0.id}))")
            print("Synced devices: \(syncedDevices.map({$0.id}))")
            for possiblePeripheral in possiblePeripherals{
                if possiblePeripheral.state == .connected {
                    // possiblePeripherals is for testing connections, should not be connected
                    central.cancelPeripheralConnection(peripheral)
                }
            }
            for cbPeripheral in cbPeripherals{
                if cbPeripheral.state == .connected {
                    // cbPeripherals is for testing connections, should not be connected
                    central.cancelPeripheralConnection(peripheral)
                }
            }
            // possiblePeripherals = []
            // leave discovery after 10 repeats and turning off scan
            if appDelegate.syncedDevices.count > 0 {
                var cbUUIDs: [CBUUID] = []
                for uuID in appDelegate.syncedDevices.map({$0.identifier}){
                    cbUUIDs.append(CBUUID(nsuuid: uuID))
                }
                // print("Looking for \(cbUUIDs.last!)")
                appDelegate.duplicateDeviceCount = 0
                //scanForPeripherals(withServices: cbUUIDs, options: nil)
                //appDelegate.deviceManager.scanForPeripherals(withServices: cbUUIDs, options: nil)
                // maybe indicate multiple somehow on homescreen later

            }
            return
        }
        */
        // ask for those that want to connect
        if let connectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool{
            print("Connectable: \(connectable)")
            if connectable{
                if possiblePeripherals.contains(peripheral){
                    duplicateDeviceCount += 1
                    return
                }
                self.possiblePeripherals.append(peripheral)
                if !cbPeripherals.contains(peripheral) && peripheral.state == .disconnected{
                    // tests connection among those that say they're connectable
                    peripheral.delegate = self
                    print("Attempting connection to \(peripheral.id)")
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?){
        print("didReadRSSI \(RSSI)")
        deviceRSSIs[peripheral]! = RSSI
    }
    

    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Momentarily connected to: \(peripheral.id)")
        print("Last power reading: \(Double(deviceRSSIs[peripheral]!))")
        switch peripheral.state {
        case .connected:
            peripheral.readRSSI()
            // App tests connection and transfers from possiblePeripherals to cbPeripherals upon passing
            if !cbPeripherals.contains(peripheral) && possiblePeripherals.contains(peripheral){
                if let myIndex = possiblePeripherals.index(of: peripheral){
                    possiblePeripherals.remove(at: myIndex)
                    cbPeripherals.append(peripheral)
                    let testResult = "passed test, and moved to cbPeripherals."
                    print("\(peripheral.id) \(testResult)")
                }
            }
            if !syncedDevices.contains(peripheral){
                print("Cancelling: \(peripheral.id) just testing.")
            }else{
                print("Cancelling: \(peripheral.id) so that we can range it")
            }
            central.cancelPeripheralConnection(peripheral)
        case .connecting, .disconnected, .disconnecting:
            print("\(peripheral.id) unavailable to take commands.")
        }
    }
}





