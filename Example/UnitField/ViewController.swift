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
//import UnitFieldRx

class ViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var unitField: UnitField!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        unitField.backgroundColor = .white
        
        unitField.textFont = UIFont.systemFont(ofSize: 22)
        unitField.textColor = .lightGray
        unitField.trackTintColor = .orange
//        unitField.cursorColor = nil
        unitField.unitSize = CGSize(width: 35, height: 35)
        unitField.isUserInteractionEnabled = true
        
        _ = unitField.becomeFirstResponder()
        
        unitField.rx
            .text
            .compactMap { $0 }
            .subscribe { [weak self] (text) in
                guard let self = self else { return }
                debugPrint("current text: \(text)")
                self.unitField.tipError()
                if text.count == 4 {
                    self.unitField.tipLoading()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.unitField.tipError()
                        if text != "1111" {
                        }
                    }
                }
                

            } onError: { (error) in
                debugPrint("error:\(error)")
            } onCompleted: {
                debugPrint("completed")
            } onDisposed: {
                debugPrint("disposeb")
            }
            .disposed(by: disposeBag)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(endF))
        scrollView.addGestureRecognizer(tap)
    }
    
    @objc func endF() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}

