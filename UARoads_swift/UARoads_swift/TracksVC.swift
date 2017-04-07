//
//  TracksVC.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import UIKit

class TracksVC: BaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConstraints()
        setupInterface()
        setupRx()
    }
    
    func setupConstraints() {
        //
    }
    
    func setupInterface() {
        title = NSLocalizedString("Recorded tracks", comment: "title")
    }
    
    func setupRx() {    
        //
    }
}
