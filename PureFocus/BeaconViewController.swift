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

class BeaconViewController: UIViewController {
    
    @IBOutlet weak var uuID: UITextField!
    
    @IBOutlet weak var statusTextfield: UITextField!
    
    @IBOutlet weak var beaconList: UIPickerView!
    
    var beaconUUID: String!{
        didSet{
            print("beaconUUID: \(beaconUUID!)")
        }
    }
    /*
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
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let validUUID = beaconUUID {
             uuID.placeholder = validUUID
        }else{
            uuID?.placeholder = "Tap to enter manually"
        }
        uuID?.delegate = self
        uuID?.font = uuID.font!.withSize(UIFont.smallSystemFontSize)
        statusTextfield?.textAlignment = .center
        statusTextfield?.delegate = self
        beaconList?.delegate = self
        beaconList?.dataSource = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true) {
            print("Seguing back")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mainVC = segue.destination as! MainViewController
        mainVC.beaconUUID = self.beaconUUID
        /*
        mainVC.major = self.major
        mainVC.minor = self.minor*/
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
            beaconUUID = textField.text!
            print("Inside UUID")
        }
        if textField.accessibilityIdentifier == "Major"{
            // major = Int(textField.text!)
            print("Inside Major")
        }
        if textField.accessibilityIdentifier == "Minor"{
            print("Inside Minor")
            // minor = Int(textField.text!)
        }
        textField.resignFirstResponder()
        return true
    }
}
extension BeaconViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    
    
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        print("widthForComponent: \(component)")
        return CGFloat.init(100)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{
        print("rowHeightForComponent: \(component)")
        return CGFloat.init(100)
    }
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        print("titleForRow: \(row)")
        
        // Dynamically fill titles with array of possible beacons
        return "Beacon title"
        
    }
    /*
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?{
        print("attributedTitleForRow: \(row)")
    }// attributed title is favored if both methods are implemented
 
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView{
        
    }
 */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        print("didSelectRow: \(row)")
    }
    
    // DATA SOURCE METHODS
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        print("numberOfComponents \(pickerView)")
        return 0
    }
    
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return 0
    }
    
}
