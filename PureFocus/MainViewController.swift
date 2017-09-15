//
//  ViewController.swift
//  SimpleButtonDemo
//
//  Created by Ryan Dines on 8/15/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit
import CallKit
import CoreLocation
import Foundation
import AddressBook
import CoreTelephony
import Contacts


class MainViewController: UIViewController{
    
    // Future implementation:  You could write an API that checked how long the app has been running
    // Contacts someone if it's off.
    
    // You can use call911() and quit together to break sandbox
    
    // MARK ADD CODE:  Use starting point for greater accuracy
    
    @IBOutlet weak var callBlockStatusSwitch: UISwitch!
    
    @IBOutlet weak var setupLabel: UILabel!
    
    @IBOutlet weak var beaconButton: UIButton!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    
    @IBAction func callBackSwitchHit(_ sender: Any) {
        
        // Turns tracking of beacons on/off, could later be used as Privacy mode feature
        
        if callBlockStatusSwitch.isOn{ // = Dongle in range
            print("callBlock On")
            if let validBeaconRegion = beaconRegion{
                locationManager.startRangingBeacons(in: validBeaconRegion)
             }
            if let validBeacon = clBeacon {
                startingAccuracy = validBeacon.accuracy
            }
            // MARK ADD CODE: Tell it to use default list to block calls
            // reloadExtension()
            
        }else{
             if let validBeaconRegion = beaconRegion{
                locationManager.stopRangingBeacons(in: validBeaconRegion)
                startingAccuracy = nil
                inRangeTextField.text = ""
                inRangeTextField.placeholder = validBeaconRegion.proximityUUID.description
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.smallSystemFontSize)
             }else{
                inRangeTextField.placeholder = "Hit plus to update beacon"
            }
            print("callBlock Off")  //  = Dongle out of range
            // MARK ADD CODE: Feed it an empty list
            // reloadExtension()
            // exit(1)
        }
        
    }
    
    @IBOutlet weak var inRangeTextField: UITextField!

    @IBAction func emergencyCallHit(_ sender: Any) {
        print("Calling 911")
        call911()
        
        // MARK ADD CODE:  Add Code that gets executed in Guided Access mode
    }
    
    @IBAction func beaconButtonHit(_ sender: Any) {
        print("Beacon button hit")
        
        
    }
    
    
    // variables
    
    var callDirManager = CXCallDirectoryManager.sharedInstance
    var emergencyCall: String = "7274531901"  // change to 911 before release
    let BRAND_IDENTIFIER = "com.purefocus"
    //var beaconUUID: String! = "DF371DDF-EFD8-4728-8BA4-DCE68F82741B"
    var beaconUUID: String! = "DF371DDF-EFD8-4728-8BA4-DCE68F82741B"{
        didSet{
            print("beaconUUID: \(beaconUUID!)")
        }
    }
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
    }
    var beaconRegion: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var clBeacon: CLBeacon!
    // MARK ADD CODE:  Add range detection using accuracy and/or rssi
    var startingAccuracy: Double!
    var lastFiveReadings: [Double] = []
    var staringRssi: Int!
    var blockList: [CXCallDirectoryPhoneNumber] = [CXCallDirectoryPhoneNumber.init(17274531901)]
    var callCenter = CTCallCenter()
    var callObserver = CXCallObserver()
    var isBlocking = false
    var callDelegate: CXCallObserverDelegate!
    var callManager: CXCallObserver!

    let defaults = UserDefaults(suiteName: "group.purefocus")!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconButton.backgroundColor = UIColor.init(rgb: 0x228B22)
        beaconButton.setTitle("+", for: .normal)
        beaconButton.layer.cornerRadius = 9
        beaconButton.layer.borderWidth = 1
        inRangeTextField.placeholder = beaconUUID
        inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.smallSystemFontSize)
        monitorBeacons()
        defaults.set(false, forKey: "beaconInRange")
        defaults.synchronize()
        if major == nil{
            major = 10002
        }
        if minor == nil{
            minor = 34452
        }
        loadContacts()
        defaults.set(blockList, forKey: "blockList")
        print(defaults.bool(forKey: "beaconInRange"))
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
    func getDigits(phone :String)->Int?{
        var digits = phone.components(separatedBy: "digits=").last!
        digits = digits.components(separatedBy: ">").first!
        if digits.contains("+"){
            digits.characters.removeFirst(1)
        }
        if digits.contains(";"){
            digits.characters.removeLast(5)
        }
        if digits.characters.count == 10{
            digits.characters.insert("1", at: digits.characters.startIndex)
        }
        if digits.characters.count < 10{
            return nil
        }
        return Int(digits)
    }

    func loadContacts(){
        let contactStore = CNContactStore()
        let keys = [CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNicknameKey, CNContactPhoneNumbersKey]
        let request1 = CNContactFetchRequest(keysToFetch: keys  as [CNKeyDescriptor])
        try! contactStore.enumerateContacts(with: request1) { (contact, error) in
            for phone in contact.phoneNumbers {
                if let validPhone = self.getDigits(phone: phone.value.description){
                    print("Phone: \(validPhone)")
                    self.blockList.append(CXCallDirectoryPhoneNumber(validPhone))
                }
            }
        }
    }
    
    func monitorBeacons(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        // locationManager.requestAlwaysAuthorization()
        let uuid = UUID(uuidString: beaconUUID)!
        if major != nil && minor != nil{
            beaconRegion = CLBeaconRegion(
                proximityUUID: uuid,
                major: UInt16(major),
                minor: UInt16(minor),
                identifier: BRAND_IDENTIFIER
            )
        }else{
            beaconRegion = CLBeaconRegion(
                proximityUUID: uuid,
                major: UInt16(10002),
                minor: UInt16(34452),
                identifier: BRAND_IDENTIFIER
            )
        }
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true
        print("Loading \(beaconRegion!) into locationManager for monitoring and ranging")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        print("Monitored regions: \(locationManager.monitoredRegions)")
        print("Ranged regions: \(locationManager.rangedRegions)")
    }
    func breakSandbox(){
        call911()
        exit(1)
    }
    
    func reloadExtension(){
        validateExtension()
        callDirManager.reloadExtension(withIdentifier: "com.dimez.PureFocus.CallManager", completionHandler: { (error) in
            print("Reloading extension.")
            if let validError = error {
                print("Error loading extension: \(validError)")
            }
        })
    }
    
    func validateExtension(){
        callDirManager.getEnabledStatusForExtension(withIdentifier: "com.dimez.PureFocus.CallManager") { (cXCallDirectoryManagerEnabledStatus) in
            switch cXCallDirectoryManagerEnabledStatus.0{
            case .disabled:
                // add code: present instructions modally
                print("App extension disabled, pop instructions on enabling.")
            case .unknown:
                print("Unknown state of extension")
            case .enabled:
                print("Extension is enabled.")
            }
            if let validError = cXCallDirectoryManagerEnabledStatus.1{
                print("Error: \(validError)")
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
        beaconViewController.beaconUUID = self.beaconUUID
        beaconViewController.major = self.major
        beaconViewController.minor = self.minor
        print(beaconUUID.characters.count)
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
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {

        if beacons.count > 0 {

            if readingsAverage > 4.20{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                if self.isBlocking == true{
                    defaults.set(false, forKey: "beaconInRange")
                    self.isBlocking = false
                    reloadExtension()
                }
                
            }else{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                inRangeTextField.text = "Beacon in range"
                if self.isBlocking == false{
                    defaults.set(true, forKey: "beaconInRange")
                    self.isBlocking = true
                    reloadExtension()
                }
            }
            let beaconAccuracy = beacons.first!.accuracy
            let beaconRssi = beacons.first!.rssi
            //initialize start point
            if startingAccuracy == nil{
                startingAccuracy = beaconAccuracy
            }else{
                if lastFiveReadings.count == 5{
                    // remove old reading if full
                    lastFiveReadings.remove(at: 0)
                }
                lastFiveReadings.append(beaconAccuracy)
            }
            if staringRssi == nil {
                staringRssi = beaconRssi
            }
            clBeacon = beacons.first
        } else {
            self.inRangeTextField.text = beaconUUID
            clBeacon = nil
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

extension CLProximity: CustomStringConvertible{
    public var description: String{
        return String(self.rawValue)
    }
}


