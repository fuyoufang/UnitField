//
//  UnitFieldTextPosition.swift
//  WLUnitField
//
//  Created by Zoneyet on 2020/9/19.
//  Copyright © 2020 wayne. All rights reserved.
//

import UIKit

class UnitFieldTextPosition: UITextPosition {

    let offset: Int
    
    init(offset: Int) {
        self.offset = offset
        super.init()
    }
}

extension UnitFieldTextPosition: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return UnitFieldTextPosition(offset: self.offset)
    }
}
