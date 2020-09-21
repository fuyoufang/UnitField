//
//  UnitFieldTextRange.swift
//  WLUnitField
//
//  Created by Zoneyet on 2020/9/21.
//  Copyright © 2020 wayne. All rights reserved.
//

import Foundation

class UnitFieldTextRange: UITextRange {
    override var start: UITextPosition {
        get {
            return _start
        }
    }
    
    override var end: UITextPosition {
        get {
            return _end
        }
    }
    var _start: UnitFieldTextPosition
    var _end: UnitFieldTextPosition
    
    init(start: UnitFieldTextPosition, end: UnitFieldTextPosition) {
        self._start = start
        self._end = end
        assert(start.offset <= end.offset);
        super.init()
    }
    
    convenience init?(range: NSRange) {
        
        if range.location == NSNotFound {
            return nil
        }
        
        let start = UnitFieldTextPosition(offset: range.location)
        let end = UnitFieldTextPosition(offset: range.location + range.length)
        self.init(start: start, end: end)
        
    }
    
    //    - (NSRange)range {
    //        return NSMakeRange(_start.offset, _end.offset - _start.offset);
    //    }
}

extension UnitFieldTextRange: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return UnitFieldTextRange(start: self._start, end: self._end)
    }
}
