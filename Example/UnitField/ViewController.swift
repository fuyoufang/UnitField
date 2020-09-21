//
//  ViewController.swift
//  UnitField
//
//  Created by fuyoufang on 09/21/2020.
//  Copyright (c) 2020 fuyoufang. All rights reserved.
//

import UIKit
import UnitField

class ViewController: UIViewController {

    @IBOutlet weak var unitField: UnitField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unitField.backgroundColor = .white
        _ = unitField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

