//
//  ViewController.swift
//  UnitField
//
//  Created by fuyoufang on 09/21/2020.
//  Copyright (c) 2020 fuyoufang. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import UnitField
import RxUnitField

class ViewController: UIViewController {

    @IBOutlet weak var unitField: UnitField!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        unitField.backgroundColor = .white
        _ = unitField.becomeFirstResponder()
        
        unitField.rx
            .text
            .subscribe { (test) in
                debugPrint("current text: \(test ?? "")")
            } onError: { (error) in
                debugPrint("error:\(error)")
            } onCompleted: {
                debugPrint("completed")
            } onDisposed: {
                debugPrint("disposeb")
            }
            .disposed(by: disposeBag)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

