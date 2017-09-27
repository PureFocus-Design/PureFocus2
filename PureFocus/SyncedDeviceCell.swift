//
//  SyncedDeviceCell.swift
//  PureFocus
//
//  Created by Ryan Dines on 9/27/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import Foundation
import UIKit

class SyncedDeviceCell: UITableViewCell{
    
    @IBOutlet weak var deviceName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.init(red: 255, green: 255, blue: 204)
        // print("SyncedDeviceCell initialized")
    }
    
}
