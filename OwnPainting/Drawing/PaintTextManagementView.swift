//
//  PaintTextManagementView.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

final class PaintTextManagementView: UIView, UITextViewDelegate {
    enum FontSize: CGFloat {
        case s = 49.5
        case m = 100
        case l = 300
    }
    
    private let inputMargin: CGFloat = 3
    private let dateUtil: DateUtil = DateUtil()
    private var layer_id: String = ""
    internal weak var paintView: PaintView?
    private var keyboardOffset: CGFloat?
    var widthScrollView: CGFloat?
    
    private var fontSize: UIFont? = UIFont(name: "Helvetica Neue", size: 49.5) {
        didSet {
            guard let paintView = paintView else {
                return
            }
            var attributes = textView.typingAttributes
            guard let font = attributes[NSAttributedString.Key.font] as? UIFont else {
                return
            }
            guard let newFont = UIFont(name: font.fontName, size: fontSize?.pointSize ?? 0.0 * paintView.zoomScale) else {
                return
            }
            attributes[NSAttributedString.Key.font] = newFont
            
            textView.attributedText = NSAttributedString(string: textView.text, attributes: attributes)
            
            let maxSize = CGSize(width: frame.size.width - textView.frame.origin.x, height: frame.size.height - textView.frame.origin.y)
            var textRect = NSString(string: textView.attributedText.string).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            textRect.origin = textView.frame.origin
            textRect.size.width += (inputMargin / paintView.zoomScale)
            textRect.size.height += (inputMargin / paintView.zoomScale)
            
            textView.frame = textRect
        }
    }
    
    override var isHidden: Bool {
        willSet {
            if newValue {
                textView.resignFirstResponder()
            }
        }
        didSet {
            textView.frame = .zero
            textView.attributedText = nil
        }
    }
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainerInset = .zero
        tv.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        tv.isScrollEnabled = false
        return tv
    }()
    
 
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    override func removeFromSuperview() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        textView.inputAccessoryView = nil
        textView.removeFromSuperview()
        super.removeFromSuperview()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview {
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        didEndInputText()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        didEndInputText()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let paintView = paintView else {
            return
        }
        
        let maxSize = CGSize(width: widthScrollView ?? frame.size.width - textView.frame.origin.x, height: frame.size.height - textView.frame.origin.y)
        
        if textView.attributedText.length == 0 {
            let attributes = textView.typingAttributes
            
            var textRect = NSString(string: "aa").boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            textRect.origin = textView.frame.origin
            let width = textRect.size.width + inputMargin / paintView.zoomScale
            let height = textRect.size.height + inputMargin / paintView.zoomScale
            
            if textRect.origin.x + width <= frame.size.width {
                textRect.size.width = width
            }
//            if textRect.origin.y + height <= frame.size.height {
//                textRect.size.height = height
//            }
            
            textView.frame = textRect
            
        } else {
            let attributes = textView.attributedText.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: textView.attributedText.length))

            var textRect = NSString(string: textView.attributedText.string).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            textRect.origin = textView.frame.origin
            print(textRect.size.width)
            let width = textRect.size.width + inputMargin / paintView.zoomScale
            let height = textRect.size.height + inputMargin / paintView.zoomScale
            
            if textRect.origin.x + width <= frame.size.width {
                textRect.size.width = width
            }
//            textRect.size.width = width
            if textRect.origin.y + height <= frame.size.height {
                textRect.size.height = height
            }
            
            textView.frame = textRect
        }
    }
    
    @objc func keyboardWillBeShown(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let delta = textView.frame.origin.y + textView.frame.size.height - keyboardScreenEndFrame.origin.y
        guard delta > 0 else {
            return
        }
        keyboardOffset = delta
        
        guard let scrollView = paintView?.superview?.superview as? UIScrollView else {
            return
        }
        scrollView.contentOffset.y += (delta + scrollView.zoomScale / scrollView.minimumZoomScale)
        textView.frame.origin.y -= delta
    }
    
    @objc func keyboardWillBeHidden(_ notification: Notification) {
        guard let delta = keyboardOffset else {
            return
        }
        keyboardOffset = nil
        guard let scrollView = paintView?.superview?.superview as? UIScrollView else {
            return
        }
        scrollView.contentOffset.y -= (delta + scrollView.zoomScale / scrollView.minimumZoomScale)
        textView.frame.origin.y += delta
    }
    
    func addText(point: CGPoint, textColor: UIColor) {
        guard let point = paintView?.convert(point, to: self) else {
            return
        }
        
        isHidden = false
        
        let font = UIFont(name: "Helvetica Neue", size: fontSize?.pointSize ?? 0.0 * paintView!.zoomScale) ?? UIFont.systemFont(ofSize: fontSize?.pointSize ?? 0.0 * paintView!.zoomScale, weight: .regular)

        
        layer_id = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
        
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineBreakMode = .byCharWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.kern: 0.0,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        
        textView.typingAttributes = attributes
        
        let maxSize = bounds.size
        var textRect = NSString(string: "aa").boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        textRect.size.width += (inputMargin / paintView!.zoomScale)
        textRect.size.height += (inputMargin / paintView!.zoomScale)
        
        textView.frame = CGRect(x: 0, y: 0, width: textRect.size.width, height: textRect.size.height)
        textView.center = CGPoint(x: point.x + textRect.size.width/2, y: point.y)
        
        textView.becomeFirstResponder()
    }
    
    func editText(layer: PaintLayer, frame: CGRect) {
        guard var rect = paintView?.convert(frame, to: self) else {
            return
        }
        rect.size.width += (inputMargin / paintView!.zoomScale)
        rect.size.height += (inputMargin / paintView!.zoomScale)
        
        var attributes = layer.text?.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: layer.text?.length ?? 0)) ?? [:]
        print(attributes)
        let font = attributes[NSAttributedString.Key.font] as! UIFont
        attributes[NSAttributedString.Key.font] = UIFont(name: font.fontName, size: font.pointSize * paintView!.zoomScale)
        fontSize = font
        
//        if let f = FontSize(rawValue: font.pointSize) {
//            fontSize = f
//        } else {
//            fontSize = .l
//        }
        
        layer_id = layer.identifier
        
        isHidden = false
        
        textView.typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: layer.text?.string ?? "", attributes: attributes)
        textView.frame = rect
        
        textView.becomeFirstResponder()
    }
    
    func didEndInputText() {
        defer {
            layer_id = ""
            textView.resignFirstResponder()
            textView.frame = .zero
            textView.text = ""
            isHidden = true
        }
        guard let attributedText = textView.attributedText, attributedText.length > 0 else {
            return
        }
        guard let paintView = paintView else {
            return
        }
        let rect = convert(textView.frame, to: paintView)
        
        var attributes = attributedText.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: attributedText.length))
        
        guard let font = attributes[NSAttributedString.Key.font] as? UIFont else {
            return
        }
        attributes[NSAttributedString.Key.font] = UIFont(name: font.fontName, size: fontSize?.pointSize ?? 0.0)
        
        guard let style = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle else {
            return
        }
        attributes[NSAttributedString.Key.paragraphStyle] = style
        
        guard let kern = attributes[NSAttributedString.Key.kern] as? NSNumber else {
            return
        }
        attributes[NSAttributedString.Key.kern] = CGFloat(truncating: kern) / paintView.zoomScale
        
        paintView.text(textView.text, attributes: attributes, layer_id: layer_id, rect: rect)
    }
    
    @objc func complete(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        didEndInputText()
    }
    
    @objc func changeSize(_ sender: UISegmentedControl) {
//        if sender.selectedSegmentIndex == 0 {
//            fontSize = .l
//        } else if sender.selectedSegmentIndex == 1 {
//            fontSize = .m
//        } else if sender.selectedSegmentIndex == 2 {
//            fontSize = .s
//        }
    }
    
    private func setupViews() {
        
        isHidden = true
        clipsToBounds = true
        backgroundColor = .clear
        
        addSubview(textView)
        textView.delegate = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let complete = UIBarButtonItem(title: "done", style: .plain, target: self, action: #selector(complete(_:)))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [
            spacer,
            complete
        ]
        textView.inputAccessoryView = toolbar
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
}
