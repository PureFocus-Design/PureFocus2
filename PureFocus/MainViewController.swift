//
//  ViewController.swift
//  SimpleButtonDemo
//
//  Created by Ryan Dines on 8/15/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit
import CoreLocation
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
    
    var locationManager: CLLocationManager!
    let BRAND_IDENTIFIER = "com.purefocus"
    var syncedDevices: [CBPeripheral] = []
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
    }
    var lastFiveReadings: [Double] = []
    
    // Device setup
    
    var beaconViewController: BeaconViewController!
    var locationTrackingAuthorized: Bool = false

    
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
    
    // MARK ADD CODE: NSCoding, persist data instead of hard code UUID
    
    func setupView(){
        beaconButton.backgroundColor = UIColor.init(rgb: 0x228B22)
        beaconButton.setTitle("+", for: .normal)
        beaconButton.layer.cornerRadius = 9
        beaconButton.layer.borderWidth = 1
        mainVCButton.layer.cornerRadius = 9
        mainVCButton.layer.borderWidth  = 1
        deviceVCButton.layer.cornerRadius = 9
        deviceVCButton.layer.borderWidth = 1
        allowVCButton.layer.cornerRadius = 9
        allowVCButton.layer.borderWidth = 1
        SettingsVCButton.layer.cornerRadius = 9
        SettingsVCButton.layer.borderWidth = 1
        iconView.layer.cornerRadius = 9
        iconView.layer.borderWidth = 1
        if let validBeacon = syncedDevices.last {
            inRangeTextField.textAlignment = .left
            inRangeTextField.placeholder = validBeacon.identifier.uuidString
        }else{
            inRangeTextField.textAlignment = .center
            inRangeTextField.placeholder = "Tap + button to add beacon"
        }
        inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.smallSystemFontSize)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if !locationTrackingAuthorized{
            print("Seguing to auth page")
            initializeLocationManager()
        }else{
            rangeBeacons()
        }
        print("syncedDevices: \(syncedDevices)")
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isLandscape{
            logoImage.isHidden = true
        }else{
            logoImage.isHidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func rangeBeacons(){
        for region in beaconRegions{
            print("Loading \(region) into locationManager for ranging")
            locationManager.startRangingBeacons(in: region)
        }
    }
    
    func initializeLocationManager(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true

    }
    
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
        beaconViewController.syncedDevices = syncedDevices
    }
}



extension MainViewController: CLLocationManagerDelegate {
    
    var readingsAverage: Double{
        var total = 0.0
        lastFiveReadings.forEach { (reading) in
            total += reading
        }
        return total/Double(lastFiveReadings.count)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedAlways:
            locationTrackingAuthorized = true
        default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        if beacons.count > 0 && locationTrackingAuthorized {
            
            if readingsAverage > 4.20{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                inRangeTextField.text = "Beacon out of range"
                
                if isLocked{
                    
                    alamo.singleAppModeLock(enable: false)
                    isLocked = false
                    if self.isBlocking == true{
                        self.isBlocking = false
                        if UIAccessibilityIsGuidedAccessEnabled(){
                            print("Disabling GuidedAccess")
                            UIAccessibilityRequestGuidedAccessSession(false){
                                success in
                                print("Request single app mode off success: \(success)")
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
                        // defaults.set(true, forKey: "beaconInRange")
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
                let beaconAccuracy = beacons.last!.accuracy
                let beaconRssi = beacons.last!.rssi
                
                if lastFiveReadings.count == 5{
                    // remove old reading if full
                    lastFiveReadings.remove(at: 0)
                }
                lastFiveReadings.append(beaconAccuracy)

            } else {
                if syncedDevices.count > 0{
                    self.inRangeTextField.text = syncedDevices.last!.identifier.uuidString
                }
            }
        }
        func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
            let beaconRegion = region as! CLBeaconRegion
            print("Did enter region: " + (beaconRegion.major?.stringValue)!)
        }
        
        func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            let beaconRegion = region as! CLBeaconRegion
            print("Did exit region: " + (beaconRegion.major?.stringValue)!)
        }
    }
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

extension CLProximity: CustomStringConvertible{
    public var description: String{
        return String(self.rawValue)
    }
}
extension BeaconViewController: SendDataProtocol{
    func sendData(syncedDevices cbPeripherals: [CBPeripheral]) {
        self.cbPeripherals = cbPeripherals
    }
}


