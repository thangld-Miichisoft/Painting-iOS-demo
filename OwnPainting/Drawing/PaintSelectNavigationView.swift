//
//  PaintSelectNavigationView.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

protocol PaintSelectNavigationViewDelegate: AnyObject {
    func willMove(point: PaintSelectNavigationView.Point)
    func didMove(point: PaintSelectNavigationView.Point, delta: CGPoint)
    func didDeMove(point: PaintSelectNavigationView.Point)
}

final class PaintSelectNavigationView: UIView, UIGestureRecognizerDelegate {
    
    enum Point {
        case start
        case end
        case upperLeft
        case upperRight
        case bottomLeft
        case bottomRight
        case centerLeft
        case centerRight
        case general(Int)
        case upperCenter
        case bottomCenter
        
        func toInt() -> Int {
            switch self {
            case .start:
                return -1
            case .end:
                return -2
            case .upperLeft:
                return -3
            case .upperRight:
                return -4
            case .bottomLeft:
                return -5
            case .bottomRight:
                return -6
            case .centerLeft:
                return -7
            case .centerRight:
                return -8
            case .general(let i):
                return i
            case .upperCenter:
                return -9
            case .bottomCenter:
                return -10
            }
        }
        
        init?(rawValue: Int) {
            if rawValue >= 0 {
                self = .general(rawValue)
            } else if rawValue == -1 {
                self = .start
            } else if rawValue == -2 {
                self = .end
            } else if rawValue == -3 {
                self = .upperLeft
            } else if rawValue == -4 {
                self = .upperRight
            } else if rawValue == -5 {
                self = .bottomLeft
            } else if rawValue == -6 {
                self = .bottomRight
            } else if rawValue == -7 {
                self = .centerLeft
            } else if rawValue == -8 {
                self = .centerRight
            } else if rawValue == -9 {
                self = .upperCenter
            } else if rawValue == -10 {
                self = .bottomCenter
            } else {
                return nil
            }
        }
    }
    
    internal var point: Point?
    private var contentsScale: CGFloat = 1
    internal var zoomScale: CGFloat = 1
    
    weak var delegate: PaintSelectNavigationViewDelegate?
    
    private var panGesture: UIPanGestureRecognizer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawCircle()
        initItems()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawCircle()
        initItems()
    }
    
    private func initItems() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    override func removeFromSuperview() {
        delegate = nil
        point = nil
        
        if let _: UIPanGestureRecognizer = panGesture {
            removeGestureRecognizer(panGesture)
            panGesture = nil
        }
        
        if let sublayers = layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
            layer.sublayers = nil
        }
        super.removeFromSuperview()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let layers = layer.sublayers?.filter({ $0.name == "Circle" }).compactMap({ $0 as? CAShapeLayer }) else {
            return
        }
        
        let dia: CGFloat = 20 * contentsScale / zoomScale
        for layer in layers {
            layer.lineWidth = 1 * contentsScale / zoomScale
            layer.path = UIBezierPath(ovalIn: CGRect(x: (frame.size.width - dia) / 2, y: (frame.size.height - dia) / 2, width: dia, height: dia)).cgPath
        }
    }
    
    @objc func pan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            if let point = point {
                delegate?.willMove(point: point)
            }
        }
        
        let move: CGPoint = gesture.translation(in: self)
        
        if let point = point {
            delegate?.didMove(point: point, delta: move)
        }
        
        gesture.setTranslation(CGPoint.zero, in: self)
        
        if gesture.state == UIGestureRecognizer.State.ended || gesture.state == UIGestureRecognizer.State.cancelled {
            if let point = point {
                delegate?.didDeMove(point: point)
            }
        }
    }
    
    private func drawCircle() {
        
        backgroundColor = UIColor.clear
        
        let layer: CAShapeLayer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor(red: 100 / 255, green: 149 / 255, blue: 237 / 255, alpha: 1).cgColor
        layer.lineWidth = 1 * contentsScale / zoomScale
        layer.name = "Circle"
        self.layer.addSublayer(layer)
    }
    
}
