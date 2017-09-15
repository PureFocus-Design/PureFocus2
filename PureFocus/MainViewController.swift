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

class MainViewController: UIViewController{
    
    // Future implementation:  You could write an API that checked how long the app has been running
    // Contacts someone if it's off.
    
    // MARK ADD CODE:  Use starting point for greater accuracy
    
    var callDirManager = CXCallDirectoryManager.sharedInstance
    var emergencyCall: String = "7274531901"  // change to 911 before release
    let BRAND_IDENTIFIER = "com.purefocus"
    var beaconUUID: String! = "DF371DDF-EFD8-4728-8BA4-DCE68F82741B"{
        didSet{
            print("beaconUUID: \(beaconUUID!)")
        }
    }
    var major: Int!
    var minor: Int!
    var beaconRegion: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var clBeacon: CLBeacon!
    // MARK ADD CODE:  Improve range detection using starting accuracy and/or rssi
    var startingAccuracy: Double!
    var lastFiveReadings: [Double] = []
    var staringRssi: Int!
    var blockList: [CXCallDirectoryPhoneNumber] = []
    let alamo = AlamoNetwork()
    
    var defaults = UserDefaults(suiteName: "group.purefocus")!
    
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
    var isBlocking = false

    
    @IBOutlet weak var callBlockStatusSwitch: UISwitch!
    
    @IBOutlet weak var setupLabel: UILabel!
    
    @IBOutlet weak var beaconButton: UIButton!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    
    @IBAction func callBackSwitchHit(_ sender: Any) {
        
        alamo.clientCheckIn()
        // Turns tracking of beacons on/off, could later be used as Privacy mode feature
        
        if callBlockStatusSwitch.isOn{
            print("callBlock On")
            if let validBeaconRegion = beaconRegion{
                locationManager.startRangingBeacons(in: validBeaconRegion)
             }
            if let validBeacon = clBeacon {
                startingAccuracy = validBeacon.accuracy
            }
            
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
            print("callBlock Off")
        }
        
    }
    
    @IBOutlet weak var inRangeTextField: UITextField!

    @IBAction func emergencyCallHit(_ sender: Any) {
        print("Calling 911")
        call911()
    }
    
    @IBAction func beaconButtonHit(_ sender: Any) {
        print("Beacon button hit")
        
        
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
        if major == nil{
            major = 10002
        }
        if minor == nil{
            minor = 34452
        }
        defaults.set(blockList, forKey: "blockList")
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
        return Int(digits)
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
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
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
            print(beacons.first!)
            // MARK ADD CODE:  Remove extension implementation and API calls
            
            if readingsAverage > 4.20{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                inRangeTextField.text = "Beacon out of range"
                // reload extension only if the isBlocking changes
                if self.isBlocking == true{
                    defaults.set(false, forKey: "beaconInRange")
                    self.isBlocking = false
                    // reloadExtension()
                }
                // reloadExtension()
            }else{
                inRangeTextField.font = inRangeTextField.font!.withSize(UIFont.systemFontSize)
                inRangeTextField.textAlignment = .center
                inRangeTextField.text = "Beacon in range"
                // reload extension only if the isBlocking changes
                if self.isBlocking == false{
                    defaults.set(true, forKey: "beaconInRange")
                    self.isBlocking = true
                    // reloadExtension()
                }
                // reloadExtension()
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
