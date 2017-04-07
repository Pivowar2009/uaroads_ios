//
//  SettingsVC.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import UIKit

class SettingsVC: BaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConstraints()
        setupInterface()
        setupRx()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        //
    }
    
    override func setupInterface() {
        super.setupInterface()
        
        title = NSLocalizedString("Settings", comment: "title")
    }
    
    override func setupRx() {
        super.setupRx()
        
        //
    }
}
