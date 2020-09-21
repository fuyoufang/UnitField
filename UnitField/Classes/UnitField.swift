//
//  UnitField.swift
//  WLUnitField
//
//  Created by Zoneyet on 2020/9/19.
//  Copyright © 2020 wayne. All rights reserved.
//

import UIKit

//#ifdef NSFoundationVersionNumber_iOS_9_x_Max
//    NSNotificationName const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
//    NSNotificationName const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
//#else
//    NSString *const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
//    NSString *const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
//#endif


public protocol UnitFieldDelegate: UITextFieldDelegate {

    func unitField(_ uniField: UnitField, shouldChangeCharactersInRange range: Range<Int>, replacementString string: String) -> Bool

}

/**
 UnitField 的外观风格
 
 - WLUnitFieldStyleBorder: 边框样式, UnitField 的默认样式
 - WLUnitFieldStyleUnderline: 下滑线样式
 */
enum UnitFieldStyle {
    case border
    case underline
}

//@protocol WLUnitFieldDelegate;


open class UnitField: UIControl {
    
    public var delegate: UnitFieldDelegate?
    
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
    
    
    //    #if TARGET_INTERFACE_BUILDER
    /**
     允许输入的个数。
     目前 WLUnitField 允许的输入单元个数区间控制在 1 ~ 8 个。任何超过该范围内的赋值行为都将被忽略。
     */
    var inputUnitCount: UInt = 6 {
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
    var style: UnitFieldStyle = .border {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    //    #endif
    
    /**
     每个 Unit 之间的距离，默认为 0
     ┌┈┈┈┬┈┈┈┬┈┈┈┬┈┈┈┐
     ┆ 1 ┆ 2 ┆ 3 ┆ 4 ┆       unitSpace is 0.
     └┈┈┈┴┈┈┈┴┈┈┈┴┈┈┈┘
     ┌┈┈┈┐┌┈┈┈┐┌┈┈┈┐┌┈┈┈┐
     ┆ 1 ┆┆ 2 ┆┆ 3 ┆┆ 4 ┆    unitSpace is 6
     └┈┈┈┘└┈┈┈┘└┈┈┈┘└┈┈┈┘
     */
    var unitSpace: Int = 0 {
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
    var borderRadius: CGFloat = 0 {
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
    var borderWidth: CGFloat = 1 {
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
    var textFont: UIFont = UIFont.systemFont(ofSize: 22) {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     设置文本颜色
     */
    var textColor: UIColor = UIColor.darkGray {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    //    var tintColor: UIColor
    
    /**
     如果需要完成一个 unit 输入后显示地指定已完成的 unit 颜色，可以设置该属性。默认为 nil。
     注意：
     该属性仅在`unitSpace`属性值大于 2 时有效。在连续模式下，不适合颜色跟踪。可以考虑使用`cursorColor`替代
     */
    var trackTintColor: UIColor? {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     用于提示输入的焦点所在位置，设置该值后会产生一个光标闪烁动画，如果设置为空，则不生成光标动画。
     */
    var cursorColor: UIColor = .orange {
        didSet {
            cursorLayer.backgroundColor = cursorColor.cgColor
            resetCursorStateIfNeeded()
        }
    }
    
    /**
     当输入完成后，是否需要自动取消第一响应者。默认为 NO。
     */
    var autoResignFirstResponderWhenInputFinished = false
    
    /**
     每个 unitfield 的大小, 默认为 44x44
     */
    var unitSize: CGSize = CGSize(width: 44, height: 44) {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    var characters = [Character]()
    
    let cursorLayer: CALayer = {
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
    //
    var mBackgroundColor: UIColor = .clear
    var mCtx: CGContext?
    //
    var mMarkedText: String? = nil
    
    @objc convenience init(inputUnitCount count: UInt) {
        self.init(style: .border, inputUnitCount: count)
    }
    
    
    init(style: UnitFieldStyle, inputUnitCount count: UInt) {
        assert(count > 0, "UnitField must have one or more input units.")
        assert(count <= 8, "UnitField can not have more than 8 input units.")
        self.style = style
        self.inputUnitCount = count
        if #available(iOS 12.0, *) {
            textContentType = .oneTimeCode
        } else if #available(iOS 10.0, *) {
            #warning("todo")
            textContentType = .name
        } else {
            textContentType = .init(rawValue: "")
        }
        super.init(frame: .zero)
        initialize()
    }
    
    required public init?(coder: NSCoder) {
        inputUnitCount = 4
        if #available(iOS 12.0, *) {
            textContentType = .oneTimeCode
        } else if #available(iOS 10.0, *) {
            #warning("todo")
            textContentType = .name
        } else {
            textContentType = .init(rawValue: "")
        }
        super.init(coder: coder)
        initialize()
    }
    
    //    - (instancetype)initWithFrame:(CGRect)frame {
    //        if (self = [super initWithFrame:frame]) {
    //            inputUnitCount = 4;
    //            [self initialize];
    //        }
    //
    //        return self;
    //    }
    //
    //
    //    - (instancetype)initWithCoder:(NSCoder *)aDecoder {
    //        if (self = [super initWithCoder:aDecoder]) {
    //
    //            [self initialize];
    //        }
    //
    //        return self;
    //    }
    //
    //
    
    
    
    func initialize() {
        backgroundColor = .clear
        isOpaque = false
        
        unitSpace = 12
        
        borderRadius = 0
        borderWidth = 1
        
        /**
         Supporting iOS12 SMS verification code, keyboardType must be UIKeyboardTypeNumberPad to localizable.
         
         Must set textContentType to UITextContentTypeOneTimeCode
         */
        
        tintColor = UIColor.lightGray
        trackTintColor = .orange
        cursorColor = .orange
        
        
        cursorLayer.backgroundColor = cursorColor.cgColor
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
            //[[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidBecomeFirstResponderNotification object:nil];
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
            //            [[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidResignFirstResponderNotification object:nil];
        }
        return result
    }
    
    
    
    open override func draw(_ rect: CGRect) {
        /*
         *  绘制的线条具有宽度，因此在绘制时需要考虑该因素对绘制效果的影响。
         */
        let width = (Int(rect.size.width) + Int(unitSpace)) / Int(inputUnitCount) - Int(unitSpace)
        let height = Int(rect.size.height)
        let unitSize = CGSize(width: width, height: height)
        mCtx = UIGraphicsGetCurrentContext();
        
        self.fill(rect: rect, unitSize: unitSize)
        self.drawBorder(rect: rect, unitSize: unitSize)
        
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
        mBackgroundColor.setFill()
        
        let radius = style == .border ? borderRadius : 0
        
        if (unitSpace < 2) {
            let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            mCtx?.addPath(bezierPath.cgPath)
        } else {
            for i in 0 ..< inputUnitCount {
                //            CGRect unitRect = CGRectMake(i * (unitSize.width + unitSpace),
                //                                         0,
                //                                         unitSize.width,
                //                                         unitSize.height);
                //            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
                //            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:radius];
                //            CGContextAddPath(mCtx, bezierPath.CGPath);
            }
        }
        
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
        
        //    CGRect bounds = CGRectInset(rect, _borderWidth * 0.5, _borderWidth * 0.5);
        //
        //    if (_style == WLUnitFieldStyleBorder) {
        //        [self.tintColor setStroke];
        //        CGContextSetLineWidth(mCtx, _borderWidth);
        //        CGContextSetLineCap(mCtx, kCGLineCapRound);
        //
        //        if (unitSpace < 2) {
        //            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:_borderRadius];
        //            CGContextAddPath(mCtx, bezierPath.CGPath);
        //
        //            for (int i = 1; i < inputUnitCount; ++i) {
        //                CGContextMoveToPoint(mCtx, (i * unitSize.width), 0);
        //                CGContextAddLineToPoint(mCtx, (i * unitSize.width), (unitSize.height));
        //            }
        //
        //        } else {
        //            for (int i = (int)characters.count; i < inputUnitCount; i++) {
        //                CGRect unitRect = CGRectMake(i * (unitSize.width + unitSpace),
        //                                             0,
        //                                             unitSize.width,
        //                                             unitSize.height);
        //                unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
        //                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
        //                CGContextAddPath(mCtx, bezierPath.CGPath);
        //            }
        //        }
        //
        //        CGContextDrawPath(mCtx, kCGPathStroke);
        //    }
        //    else {
        //
        //        [self.tintColor setFill];
        //        for (int i = (int)characters.count; i < inputUnitCount; i++) {
        //            CGRect unitLineRect = CGRectMake(i * (unitSize.width + unitSpace),
        //                                         unitSize.height - _borderWidth,
        //                                         unitSize.width,
        //                                         _borderWidth);
        //            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
        //            CGContextAddPath(mCtx, bezierPath.CGPath);
        //        }
        //
        //        CGContextDrawPath(mCtx, kCGPathFill);
        //    }
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
            let unitRect = CGRect(x: i * (Int(unitSize.width) + Int(unitSpace)), y: 0, width: Int(unitSize.width), height: Int(unitSize.height))
            
            
            let yOffset = style == .border ? 0 : borderWidth
            
            if isSecureTextEntry {
                //                CGRect drawRect = CGRectInset(unitRect,
                //                                              (unitRect.size.width - _textFont.pointSize / 2) / 2,
                //                                              (unitRect.size.height - _textFont.pointSize / 2) / 2);
                //                drawRect.size.height -= yOffset;
                //                [_textColor setFill];
                //                CGContextAddEllipseInRect(mCtx, drawRect);
                //                CGContextFillPath(mCtx);
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
    
    
    /**
     绘制跟踪框，如果指定的`trackTintColor`为 nil 则不绘制
     
     @param rect 控件绘制的区域
     @param unitSize 单个 input unit 占据的尺寸
     */
    func drawTrackBorder(rect: CGRect, unitSize: CGSize) {
        //    if (_trackTintColor == nil) return;
        //
        //    if (_style == WLUnitFieldStyleBorder) {
        //        if (unitSpace < 2) return;
        //
        //        [_trackTintColor setStroke];
        //        CGContextSetLineWidth(mCtx, _borderWidth);
        //        CGContextSetLineCap(mCtx, kCGLineCapRound);
        //
        //        for (int i = 0; i < characters.count; i++) {
        //            CGRect unitRect = CGRectMake(i * (unitSize.width + unitSpace),
        //                                         0,
        //                                         unitSize.width,
        //                                         unitSize.height);
        //            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
        //            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
        //            CGContextAddPath(mCtx, bezierPath.CGPath);
        //        }
        //
        //        CGContextDrawPath(mCtx, kCGPathStroke);
        //    }
        //    else {
        //        [_trackTintColor setFill];
        //
        //        for (int i = 0; i < characters.count; i++) {
        //            CGRect unitLineRect = CGRectMake(i * (unitSize.width + unitSpace),
        //                                             unitSize.height - _borderWidth,
        //                                             unitSize.width,
        //                                             _borderWidth);
        //            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
        //            CGContextAddPath(mCtx, bezierPath.CGPath);
        //        }
        //
        //        CGContextDrawPath(mCtx, kCGPathFill);
        //    }
        
    }
    
    func resetCursorStateIfNeeded() {
        DispatchQueue.main.async {
            //            self->_cursorLayer.hidden = !self.isFirstResponder || self->_cursorColor == nil || self->inputUnitCount == self->characters.count;
            
            self.cursorLayer.isHidden = !self.isFirstResponder || self.inputUnitCount == self.characters.count
            if self.cursorLayer.isHidden {
                return
            }
            
            let width = (self.bounds.size.width + CGFloat(self.unitSpace)) / CGFloat(self.inputUnitCount) - CGFloat(self.unitSpace)
            let height = self.bounds.size.height
            let unitSize = CGSize(width: width, height: height)
            
            var unitRect = CGRect(x: CGFloat(self.characters.count) * (CGFloat(unitSize.width) + CGFloat(self.unitSpace)),
                                  y: 0,
                                  width: CGFloat(unitSize.width),
                                  height: CGFloat(unitSize.height))
            unitRect = unitRect.insetBy(dx: unitRect.size.width / 2 - 1,
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
    
    // UITextInput 必须有的属性
    public var selectedTextRange: UITextRange?
    public var markedTextStyle: [NSAttributedString.Key : Any]?
    public var markedTextRange: UITextRange? = nil
    public var inputDelegate: UITextInputDelegate?
    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)
    
    //@dynamic text;
    //@synthesize selectedTextRange = _selectedTextRange;
    
    // UITextInputTraits 代理中的属性
    public var isSecureTextEntry: Bool = false {
        didSet {
            resetCursorStateIfNeeded()
        }
    }
    
    //@property(null_unspecified,nonatomic,copy) IBInspectable UITextContentType textContentType NS_AVAILABLE_IOS(10_0); // default is nil
    public var textContentType: UITextContentType
    
    public var keyboardType: UIKeyboardType = .numberPad
    public var returnKeyType: UIReturnKeyType = .done
    public var enablesReturnKeyAutomatically: Bool = true
    public var autocorrectionType: UITextAutocorrectionType = .no
    public var autocapitalizationType: UITextAutocapitalizationType = .none
}

// UITextInput implement.
// MARK: UITextInput
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
    // - (NSArray<UITextSelectionRect *> *)selectionRectsForRange:(UnitFieldTextRange *)range { return nil; }
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
        if text == "\n" {
            _ = resignFirstResponder()
            return
        }
        
        guard text != " " else {
            return
        }
        
        if (characters.count >= inputUnitCount) {
            if autoResignFirstResponderWhenInputFinished {
                _ = resignFirstResponder()
            }
            return;
        }
        
        
        
        //    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)]) {
        //        if ([self.delegate unitField:self shouldChangeCharactersInRange:NSMakeRange(self.text.length, text.length) replacementString:text] == NO) {
        //            return;
        //        }
        //    }
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
