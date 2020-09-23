//
//  UnitField.swift
//  WLUnitField
//
//  Created by Zoneyet on 2020/9/19.
//  Copyright © 2020 wayne. All rights reserved.
//

import UIKit

extension Notification.Name {
    public static let unitFieldDidBecomeFirstResponderNotification = Notification.Name(rawValue: "UnitFieldDidBecomeFirstResponderNotification")
    public static let unitFieldDidResignFirstResponderNotification = Notification.Name(rawValue: "UnitFieldDidResignFirstResponderNotification")
}

public protocol UnitFieldDelegate: UITextFieldDelegate {
    
    func unitField(_ uniField: UnitField, shouldChangeCharactersInRange range: Range<Int>, replacementString string: String) -> Bool
}

extension UnitFieldDelegate {
    func unitField(_ uniField: UnitField, shouldChangeCharactersInRange range: Range<Int>, replacementString string: String) -> Bool {
        return true
    }
}

/**
 UnitField 的外观风格
 
 - WLUnitFieldStyleBorder: 边框样式, UnitField 的默认样式
 - WLUnitFieldStyleUnderline: 下滑线样式
 */
public enum UnitFieldStyle {
    case border
    case underline
}

open class UnitField: UIControl {
    
    public var delegate: UnitFieldDelegate?
    public var shouldChangeCharacters: ((_ range: Range<Int>, _ string: String) -> Bool)?
    
    // MARK: UITextInput 相关属性
    public var selectedTextRange: UITextRange?
    public var markedTextStyle: [NSAttributedString.Key : Any]?
    public var markedTextRange: UITextRange? = nil
    public var inputDelegate: UITextInputDelegate?
    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)
    // UITextInputTraits 代理中的属性
    public var isSecureTextEntry: Bool = false {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    @available(iOS 10.0, *)
    public var textContentType: UITextContentType? {
        get {
            return _textContentType
        }
        set {
            _textContentType = newValue
        }
    }
    
    public var keyboardType: UIKeyboardType = .numberPad
    public var returnKeyType: UIReturnKeyType = .done
    public var enablesReturnKeyAutomatically: Bool = true
    public var autocorrectionType: UITextAutocorrectionType = .no
    public var autocapitalizationType: UITextAutocapitalizationType = .none
    /**
     保留的用户输入的字符串，最好使用数字字符串，因为目前还不支持其他字符。
     */
    public var text: String? {
        get {
            guard characters.count > 0 else {
                return nil
            }
            return String(characters)
        }
        set {
            characters.removeAll()
            newValue?.forEach({ (character) in
                if self.characters.count < inputUnitCount {
                    self.characters.append(character)
                }
            })
            
            setNeedsDisplay()
            
            resetCursorStateIfNeeded()
            
            /**
             Supporting iOS12 SMS verification code, setText will be called when verification code input.
             */
            if characters.count >= inputUnitCount {
                if self.autoResignFirstResponderWhenInputFinished == true {
                    OperationQueue.main.addOperation {
                        _ = self.resignFirstResponder()
                    }
                }
            }
        }
    }
    
    // MARK: 样式配置属性
    
    //    #if TARGET_INTERFACE_BUILDER
    /**
     允许输入的个数。
     目前 WLUnitField 允许的输入单元个数区间控制在 1 ~ 8 个。任何超过该范围内的赋值行为都将被忽略。
     */
    public var inputUnitCount: UInt = 6 {
        didSet {
            if inputUnitCount > 8 || inputUnitCount < 1 {
                inputUnitCount = oldValue
                return
            }
            
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     UnitField 的外观风格, 默认为 WLUnitFieldStyleBorder.
     */
    public let style: UnitFieldStyle
    
    //    #endif
    
    /**
     每个 Unit 之间的距离
     ┌┈┈┈┬┈┈┈┬┈┈┈┬┈┈┈┐
     ┆ 1 ┆ 2 ┆ 3 ┆ 4 ┆       unitSpace is 0.
     └┈┈┈┴┈┈┈┴┈┈┈┴┈┈┈┘
     ┌┈┈┈┐┌┈┈┈┐┌┈┈┈┐┌┈┈┈┐
     ┆ 1 ┆┆ 2 ┆┆ 3 ┆┆ 4 ┆    unitSpace is 6
     └┈┈┈┘└┈┈┈┘└┈┈┈┘└┈┈┈┘
     */
    public var unitSpace: CGFloat = 12 {
        didSet {
            if (unitSpace < 2) {
                unitSpace = 0
            }
            
            self.resize()
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     设置边框圆角
     ╭┈┈┈╮╭┈┈┈╮╭┈┈┈╮╭┈┈┈╮
     ┆ 1 ┆┆ 2 ┆┆ 3 ┆┆ 4 ┆    unitSpace is 6, borderRadius is 4.
     ╰┈┈┈╯╰┈┈┈╯╰┈┈┈╯╰┈┈┈╯
     ╭┈┈┈┬┈┈┈┬┈┈┈┬┈┈┈╮
     ┆ 1 ┆ 2 ┆ 3 ┆ 4 ┆       unitSpace is 0, borderRadius is 4.
     ╰┈┈┈┴┈┈┈┴┈┈┈┴┈┈┈╯
     */
    public var borderRadius: CGFloat = 4 {
        didSet {
            if (borderRadius < 0) {
                borderRadius = oldValue
                return
            }
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     设置边框宽度，默认为 1。
     */
    public var borderWidth: CGFloat = 1 {
        didSet {
            if (borderWidth < 0) {
                borderWidth = oldValue
                return
            }
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     设置文本字体
     */
    public var textFont: UIFont = UIFont.systemFont(ofSize: 22) {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     设置文本颜色
     */
    public var textColor: UIColor = UIColor.darkGray {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     如果需要完成一个 unit 输入后显示地指定已完成的 unit 颜色，可以设置该属性。默认为 nil。
     注意：
     该属性仅在`unitSpace`属性值大于 2 时有效。在连续模式下，不适合颜色跟踪。可以考虑使用`cursorColor`替代
     */
    public var trackTintColor: UIColor? = .orange {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     用于提示输入的焦点所在位置，设置该值后会产生一个光标闪烁动画，如果设置为空，则不生成光标动画。
     */
    public var cursorColor: UIColor? = .orange {
        didSet {
            cursorLayer.backgroundColor = cursorColor?.cgColor
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     当输入完成后，是否需要自动取消第一响应者。默认为 NO。
     */
    public var autoResignFirstResponderWhenInputFinished = false
    
    /**
     每个 unitfield 的大小, 默认为 44x44
     */
    public var unitSize: CGSize = CGSize(width: 44, height: 44) {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    public var unitBackgroundColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            super.backgroundColor = backgroundColor
            resetCursorStateIfNeeded()
        }
    }
    
    open override var tintColor: UIColor! {
        didSet {
            super.tintColor = tintColor
            resetCursorStateIfNeeded()
        }
    }
    
    // MARK: Private Properties
    private lazy var _textContentType: UITextContentType? = {
        /**
         Supporting iOS12 SMS verification code, keyboardType must be UIKeyboardTypeNumberPad to localizable.
         
         Must set textContentType to UITextContentTypeOneTimeCode
         */
        if #available(iOS 12.0, *) {
            return .oneTimeCode
        } else {
            return nil
        }
    }()
    
    private var characters = [Character]()
    
    private let cursorLayer: CALayer = {
        let cursorLayer = CALayer()
        cursorLayer.isHidden = true
        cursorLayer.opacity = 1
        
        let animate = CABasicAnimation(keyPath: "opacity")
        animate.fromValue = 0
        animate.toValue = 1.5
        animate.duration = 0.5
        animate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animate.autoreverses = true
        animate.isRemovedOnCompletion = false
        animate.fillMode = .forwards
        animate.repeatCount = .greatestFiniteMagnitude
        
        cursorLayer.add(animate, forKey: nil)
        
        return cursorLayer
    }()
    
    var mCtx: CGContext?
    var mMarkedText: String? = nil
    
    // MARK: Initialize
    
    public convenience init(inputUnitCount count: UInt) {
        self.init(style: .border, inputUnitCount: count)
    }
    
    public init(style: UnitFieldStyle, inputUnitCount count: UInt) {
        assert(count > 0, "UnitField must have one or more input units.")
        assert(count <= 8, "UnitField can not have more than 8 input units.")
        self.style = style
        self.inputUnitCount = count
        
        super.init(frame: .zero)
        initialize()
        resetCursorStateIfNeeded()
    }
    
    required public init?(coder: NSCoder) {
        inputUnitCount = 4
        //style = .border
        style = .underline
        super.init(coder: coder)
        initialize()
    }

    func initialize() {
        backgroundColor = .clear
        
        tintColor = UIColor.lightGray
        cursorLayer.backgroundColor = cursorColor?.cgColor
        let point = UnitFieldTextPosition(offset: 0)
        let aNewRange = UnitFieldTextRange(start: point, end: point)
        selectedTextRange = aNewRange
        
        self.layer.addSublayer(self.cursorLayer)
        OperationQueue.main.addOperation {
            self.layoutIfNeeded()
            self.cursorLayer.position = CGPoint(x: self.bounds.width / CGFloat(self.inputUnitCount) / 2, y: self.bounds.size.height / 2)
        }
        
        setNeedsDisplay()
    }
    
    // MARK: Event
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        _ = becomeFirstResponder()
    }
    
    // MARK: Override
    
    open override var intrinsicContentSize: CGSize {
        let width = Int(inputUnitCount) * (Int(unitSize.width) + Int(unitSpace)) - Int(unitSpace)
        let height = Int(unitSize.height)
        return CGSize(width: width, height: height)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
    open override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        resetCursorStateIfNeeded()
        
        if result {
            sendActions(for: .editingDidBegin)
            NotificationCenter.default.post(name: .unitFieldDidBecomeFirstResponderNotification, object: self)
        }
        return result
    }
    
    open override var canResignFirstResponder: Bool {
        return true
    }
    
    open override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        resetCursorStateIfNeeded()
        if result {
            sendActions(for: .editingDidEnd)
            NotificationCenter.default.post(name: .unitFieldDidResignFirstResponderNotification, object: self)
        }
        return result
    }
    
    open override func draw(_ rect: CGRect) {
        /*
         *  绘制的线条具有宽度，因此在绘制时需要考虑该因素对绘制效果的影响。
         */
        let width = (rect.size.width + CGFloat(unitSpace)) / CGFloat(inputUnitCount) - unitSpace
        let height = rect.size.height
        let unitSize = CGSize(width: width, height: height)
        mCtx = UIGraphicsGetCurrentContext();
        
        fill(rect: rect, unitSize: unitSize)
        drawBorder(rect: rect, unitSize: unitSize)
        drawText(rect: rect, unitSize: unitSize)
        drawTrackBorder(rect: rect, unitSize: unitSize)
    }
    
    
    // MARK: Private
    
    /**
     在 AutoLayout 环境下重新指定控件本身的固有尺寸
     
     `-drawRect:`方法会计算控件完成自身的绘制所需的合适尺寸，完成一次绘制后会通知 AutoLayout 系统更新尺寸。
     */
    func resize() {
        invalidateIntrinsicContentSize()
    }
    
    /**
     绘制背景色，以及剪裁绘制区域
     
     @param rect 控件绘制的区域
     */
    func fill(rect: CGRect, unitSize: CGSize) {
        guard let color = unitBackgroundColor else {
            return
        }
        
        let radius = style == .border ? borderRadius : 0
        
        if (unitSpace < 2) {
            let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            mCtx?.addPath(bezierPath.cgPath)
        } else {
            for i in 0 ..< inputUnitCount {
                var unitRect = CGRect(x: CGFloat(i) * (unitSize.width + CGFloat(unitSpace)), y: 0, width: unitSize.width, height: unitSize.height)
                unitRect = unitRect.insetBy(dx: borderWidth * 0.5, dy: borderWidth * 0.5)
                let bezierPath = UIBezierPath(roundedRect: unitRect, cornerRadius: radius)
                mCtx?.addPath(bezierPath.cgPath)
            }
        }
        mCtx?.setFillColor(color.cgColor)
        mCtx?.fillPath()
    }
    
    
    /**
     绘制边框
     
     边框的绘制分为两种模式：连续和不连续。其模式的切换由`unitSpace`属性决定。
     当`unitSpace`值小于 2 时，采用的是连续模式，即每个 input unit 之间没有间隔。
     反之，每个 input unit 会被边框包围。
     
     @see unitSpace
     
     @param rect 控件绘制的区域
     @param unitSize 单个 input unit 占据的尺寸
     */
    func drawBorder(rect: CGRect, unitSize: CGSize) {
        
        if style == .border {
            tintColor.setStroke()
            mCtx?.setLineWidth(borderWidth)
            mCtx?.setLineCap(.round)
            if unitSpace < 2 {
                let bounds = rect.insetBy(dx: borderWidth * 0.5, dy: borderWidth * 0.5)
                let bezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: borderRadius)
                mCtx?.addPath(bezierPath.cgPath)
                (1..<inputUnitCount).forEach {
                    mCtx?.move(to: CGPoint(x: (CGFloat($0) * unitSize.width), y: 0))
                    mCtx?.addLine(to: CGPoint(x: CGFloat($0) * unitSize.width, y: unitSize.height))
                }
            } else {
                (UInt(characters.count) ..< self.inputUnitCount).forEach {
                    var unitRect = CGRect(x: CGFloat($0) * (unitSize.width + unitSpace), y: 0, width: unitSize.width, height: unitSize.height)
                    unitRect = unitRect.insetBy(dx: borderWidth * 0.5, dy: borderWidth * 0.5)
                    let bezierPath = UIBezierPath(roundedRect: unitRect, cornerRadius: borderRadius)
                    mCtx?.addPath(bezierPath.cgPath)
                }
            }
            
            mCtx?.drawPath(using: .stroke)
        } else {
            tintColor.setFill()
            (UInt(characters.count) ..< self.inputUnitCount).forEach {
                let unitRect = CGRect(x: CGFloat($0) * (unitSize.width + unitSpace),
                                      y: unitSize.height - borderWidth,
                                      width: unitSize.width,
                                      height: borderWidth)
                let bezierPath = UIBezierPath(roundedRect: unitRect, cornerRadius: borderRadius)
                mCtx?.addPath(bezierPath.cgPath)
            }
            
            mCtx?.drawPath(using: .fill)
        }
    }
    
    
    /**
     绘制跟踪框，如果指定的`trackTintColor`为 nil 则不绘制
     
     @param rect 控件绘制的区域
     @param unitSize 单个 input unit 占据的尺寸
     */
    func drawTrackBorder(rect: CGRect, unitSize: CGSize) {
        guard let color = trackTintColor else {
            return
        }
        
        if style == .border {
            guard unitSpace > 1 else {
                return
            }
            color.setStroke()
            mCtx?.setLineWidth(borderWidth)
            mCtx?.setLineCap(.round)
            (0..<characters.count).forEach {
                var unitRect = CGRect(x: CGFloat($0) * (unitSize.width + unitSpace), y: 0, width: unitSize.width, height: unitSize.height)
                unitRect = unitRect.insetBy(dx: borderWidth * 0.5, dy: borderWidth * 0.5)
                let bezierPath = UIBezierPath(roundedRect: unitRect, cornerRadius: borderRadius)
                mCtx?.addPath(bezierPath.cgPath)
            }
            mCtx?.drawPath(using: .stroke)
        } else {
            color.setFill()
            (0..<characters.count).forEach {
                let unitRect = CGRect(x: CGFloat($0) * (unitSize.width + unitSpace),
                                      y: unitSize.height - borderWidth,
                                      width: unitSize.width,
                                      height: borderWidth)
                let bezierPath = UIBezierPath(roundedRect: unitRect, cornerRadius: borderRadius)
                mCtx?.addPath(bezierPath.cgPath)
            }
            
            mCtx?.drawPath(using: .fill)
        }
    }
    /**
     绘制文本
     
     当处于密文输入模式时，会用圆圈替代文本。
     
     @param rect 控件绘制的区域
     @param unitSize 单个 input unit 占据的尺寸
     */
    func drawText(rect: CGRect, unitSize: CGSize) {
        guard hasText else {
            return
        }
        
        
        let attr = [NSAttributedString.Key.foregroundColor: textColor,
                    NSAttributedString.Key.font: textFont]
        
        for i in 0 ..< characters.count {
            let unitRect = CGRect(x: CGFloat(i) * (unitSize.width + unitSpace), y: 0, width: unitSize.width, height: unitSize.height)
            
            let yOffset = style == .border ? 0 : borderWidth
            
            if isSecureTextEntry {
                var drawRect = unitRect.insetBy(dx: (unitRect.size.width - textFont.pointSize / 2) / 2,
                                                dy: (unitRect.size.height - textFont.pointSize / 2) / 2)
                drawRect.size.height -= yOffset
                textColor.setFill()
                mCtx?.addEllipse(in: drawRect)
                mCtx?.fillPath()
            } else {
                let subString = NSString(string: String(characters[i]))
                
                let oneTextSize = subString.size(withAttributes: attr)
                var drawRect = unitRect.insetBy(dx: (unitRect.size.width - oneTextSize.width) / 2,
                                                dy: (unitRect.size.height - oneTextSize.height) / 2)
                
                drawRect.size.height -= yOffset
                subString.draw(in: drawRect, withAttributes: attr)
            }
        }
    }
    
    func resetCursorStateIfNeeded() {
        DispatchQueue.main.async {
            self.cursorLayer.isHidden = !self.isFirstResponder || self.inputUnitCount == self.characters.count || self.cursorColor == nil
            if self.cursorLayer.isHidden {
                return
            }
            
            let unitWidth = (self.bounds.size.width + CGFloat(self.unitSpace)) / CGFloat(self.inputUnitCount) - CGFloat(self.unitSpace)
            let unitHeight = self.bounds.size.height
            
            var unitRect = CGRect(x: CGFloat(self.characters.count) * (unitWidth + CGFloat(self.unitSpace)),
                                  y: 0,
                                  width: unitWidth,
                                  height: unitHeight)
            unitRect = unitRect.insetBy(dx: unitWidth / 2 - 1,
                                        dy: (unitRect.size.height - self.textFont.pointSize) / 2)
            
            let yOffset = self.style == .border ? 0 : self.borderWidth
            unitRect.size.height -= yOffset
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            CATransaction.setAnimationDuration(0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            self.cursorLayer.frame = unitRect
            CATransaction.commit()
        }
    }
    
}

// MARK: UITextInput implement.
extension UnitField: UITextInput {
    
    public func deleteBackward() {
        guard hasText else {
            return
        }
        inputDelegate?.textWillChange(self)
        characters.removeLast()
        sendActions(for: .editingChanged)
        self.setNeedsDisplay()
        
        resetCursorStateIfNeeded()
        inputDelegate?.textDidChange(self)
    }
    
    public func replace(_ range: UITextRange, withText text: String) {
        
    }
    
    // selectedRange is a range within the markedText
    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        mMarkedText = markedText
    }
    
    public func unmarkText() {
        if (self.text?.count ?? 0) >= self.inputUnitCount {
            mMarkedText = nil
            return
        }
        if mMarkedText != nil {
            insertText(mMarkedText!)
            mMarkedText = nil
        }
    }
    
    public var beginningOfDocument: UITextPosition {
        return UnitFieldTextPosition(offset: 0)
    }
    
    public var endOfDocument: UITextPosition {
        guard let text = self.text, text.count > 0 else {
            return UnitFieldTextPosition(offset: 0)
        }
        return UnitFieldTextPosition(offset: text.count - 1)
    }
    
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? UnitFieldTextPosition, let toPosition = toPosition as? UnitFieldTextPosition  else {
            return nil
        }
        let location = Int(min(fromPosition.offset, toPosition.offset))
        let length = Int(abs(toPosition.offset - fromPosition.offset))
        let range = NSRange(location: location, length: length)
        return UnitFieldTextRange(range: range)
    }
    
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let position = position as? UnitFieldTextPosition else {
            return nil
        }
        let end = position.offset + offset
        if (end > (self.text?.count ?? 0) || end < 0) {
            return nil
        }
        return UnitFieldTextPosition(offset: end)
    }
    
    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        guard let position = position as? UnitFieldTextPosition else {
            return UITextPosition()
        }
        return UnitFieldTextPosition(offset: position.offset + offset)
    }
    
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let position = position as? UnitFieldTextPosition, let other = other as? UnitFieldTextPosition  else {
            return .orderedSame
        }
        if position.offset < other.offset {
            return .orderedAscending
        }
        if position.offset > other.offset {
            return .orderedDescending
        }
        return .orderedSame;
    }
    
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let from = from as? UnitFieldTextPosition, let toPosition = toPosition as? UnitFieldTextPosition  else {
            return 0
        }
        return Int(toPosition.offset - from.offset)
    }
    
    
    
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        return nil
    }
    
    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        return nil
    }
    
    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        return .natural
    }
    
    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        
    }
    
    public func firstRect(for range: UITextRange) -> CGRect {
        .null
    }
    
    public func caretRect(for position: UITextPosition) -> CGRect {
        .null
    }
    
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }
    
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        return nil
    }
    
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        return nil
    }
    
    public func characterRange(at point: CGPoint) -> UITextRange? {
        return nil
    }
    
    public func text(in range: UITextRange) -> String? {
        return self.text
    }
    
    public var hasText: Bool {
        return characters.count > 0;
    }
    
    public func insertText(_ text: String) {
        guard text != "\n" else {
            _ = resignFirstResponder()
            return
        }
        
        guard text != " " else {
            return
        }
        
        guard characters.count < inputUnitCount else {
            if autoResignFirstResponderWhenInputFinished {
                _ = resignFirstResponder()
            }
            return
        }
        let range = Range<Int>(uncheckedBounds: (lower: (self.text?.count ?? 0), upper: text.count))
        
        guard self.delegate?.unitField(self, shouldChangeCharactersInRange: range, replacementString: text) ?? true else {
            return
        }
        
        guard self.shouldChangeCharacters?(range, text) ?? true else {
            return
        }
        
        self.inputDelegate?.textWillChange(self)
        
        text.forEach { (character) in
            characters.append(character)
        }
        
        if characters.count >= inputUnitCount {
            characters.removeSubrange(characters.index(0, offsetBy: Int(inputUnitCount)) ..< characters.endIndex)
            if autoResignFirstResponderWhenInputFinished {
                OperationQueue.main.addOperation {
                    _ = self.resignFirstResponder()
                }
            }
        }
        
        sendActions(for: .editingChanged)
        setNeedsDisplay()
        resetCursorStateIfNeeded()
        inputDelegate?.textDidChange(self)
    }
}
