//
//  ViewController.swift
//  SimpleButtonDemo
//
//  Created by Ryan Dines on 8/15/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
// import CoreBluetooth

// moving CoreBlueTooth to AppDelegate

let appDelegate = UIApplication.shared.delegate! as! AppDelegate

class MainViewController: UIViewController{

    // PROPERTIES
    
    // Networking and emergency calling
    
    var emergencyCall: String = "7274531901"  // change to 911 before release

    var lastFiveReadings: [Double] = []{
        willSet{
            print("Updating lastFiveReadings: \(newValue)")
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
        if appDelegate.isLocked {
            appDelegate.alamo.singleAppModeLock(enable: false)
            appDelegate.isLocked = false
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
        inRangeTextField.textAlignment = .center
        inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
        if let validBeacon = appDelegate.syncedDevices.last {
            inRangeTextField.text = "Searching for \(validBeacon.name ?? "unknown")"
        }else{
            inRangeTextField?.placeholder = "Tap + button to add beacon"
        }
    }
    // CALL BELOW FUNCTION WHEN APPDELEGATE FINDS CONNECTION
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainVC.viewDidLoad")
        setupView()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // tried delaying to avoid warning
        delay(bySeconds: 0.1) { 
            if self.isLandscape{
                self.logoImage.isHidden = true
            }else{
                self.logoImage.isHidden = false
            }
        }
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
        beaconViewController.mainVC = self
    }
    @IBAction func unwindToMain(segue:UIStoryboardSegue) { } // Hook up to icon later
    
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
/*

extension MainViewController: CBCentralManagerDelegate, CBPeripheralDelegate{
 
    
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

*/




