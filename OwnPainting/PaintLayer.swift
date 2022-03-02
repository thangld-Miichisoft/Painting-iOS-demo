//
//  PaintLayer.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

final class PaintLayer: CAShapeLayer {
    
    enum Operation: Int {
        case `default` = 0
        case new
        case edit
        case delete
    }
    
    private enum SublayerName: String {
        case value = "value"
        case fill = "fill"
        case navi = "navi"
    }
    
    internal var identifier: String = ""
    internal var type: PaintView.PaintType = .freehand {
        willSet {
            if let layers = sublayers {
                for layer in layers {
                    layer.removeFromSuperlayer()
                }
            }
        }
        didSet {
            if type == .areaRect || type == .areaPolygon || type == .areaFreehand {
                let layer = CAShapeLayer()
                layer.name = SublayerName.fill.rawValue
                layer.lineWidth = 1
                layer.strokeColor = UIColor.clear.cgColor
                layer.fillColor = strokeColor
                layer.opacity = 0.1
                addSublayer(layer)
            }
            if type == .rulerBase || type == .rulerLine || type == .rulerRect || type == .rulerPolygon || type == .rulerFreehand || type == .areaRect || type == .areaPolygon || type == .areaFreehand {
                let layer = CAShapeLayer()
                layer.name = SublayerName.value.rawValue
                layer.lineWidth = 1
                layer.strokeColor = UIColor.black.cgColor
                layer.fillColor = strokeColor
                addSublayer(layer)
            }
            if type == .rulerRect || type == .rulerPolygon || type == .rulerFreehand || type == .areaRect || type == .areaPolygon || type == .areaFreehand {
                let layer = CAShapeLayer()
                layer.name = SublayerName.navi.rawValue
                layer.lineWidth = 1
                layer.strokeColor = strokeColor
                layer.fillColor = strokeColor
                addSublayer(layer)
            }
        }
    }
    internal var points: [[CGPoint]] = [[]]
    internal var text: NSAttributedString?
    internal var number: Double?
    internal var baseLineWidth: CGFloat = 0
    internal var operation: Operation = .default
    
    internal var navigationPoint: [Int: CGPoint]? {
        if type == .line || type == .arrow {
            return [
                PaintSelectNavigationView.Point.start.toInt(): points[0][0],
                PaintSelectNavigationView.Point.end.toInt(): points[0][1]
            ]
        } else if type == .rect || type == .oval || type == .cross || type == .rulerRect || type == .areaRect {
            var dic = [Int: CGPoint]()
            dic[PaintSelectNavigationView.Point.upperLeft.toInt()] = points[0][0]
            dic[PaintSelectNavigationView.Point.upperRight.toInt()] = points[0][1]
            dic[PaintSelectNavigationView.Point.bottomLeft.toInt()] = points[0][2]
            dic[PaintSelectNavigationView.Point.bottomRight.toInt()] = points[0][3]
            return dic
        } else if type == .freehand || type == .pen || type == .highlighter || type == .rulerFreehand || type == .areaFreehand {
            guard let rect = path?.boundingBox else {
                return nil
            }
            let radius = type == .highlighter ? lineWidth / 2 : 0
            return [
                PaintSelectNavigationView.Point.upperLeft.toInt(): CGPoint(x: rect.minX - radius, y: rect.minY - radius),
                PaintSelectNavigationView.Point.upperRight.toInt(): CGPoint(x: rect.maxX + radius, y: rect.minY - radius),
                PaintSelectNavigationView.Point.bottomLeft.toInt(): CGPoint(x: rect.minX - radius, y: rect.maxY + radius),
                PaintSelectNavigationView.Point.bottomRight.toInt(): CGPoint(x: rect.maxX + radius, y: rect.maxY + radius)
            ]
        } else if type == .text {
            return [
                PaintSelectNavigationView.Point.centerLeft.toInt(): CGPoint(x: points[0][0].x, y: (points[0][0].y + points[0][1].y) / 2),
                PaintSelectNavigationView.Point.centerRight.toInt(): CGPoint(x: points[0][1].x, y: (points[0][0].y + points[0][1].y) / 2)
            ]
        } else if type == .rulerBase || type == .rulerLine {
            return [PaintSelectNavigationView.Point.start.toInt(): points[0][0],
                    PaintSelectNavigationView.Point.end.toInt(): points[0][1]]
        } else if type == .rulerPolygon || type == .areaPolygon {
            var dic = [Int: CGPoint]()
            for i in 0 ..< points[0].count {
                dic[i] = points[0][i]
            }
            return dic
        }
        return nil
    }
    
    override var strokeColor: CGColor? {
        didSet {
            if type == .rulerBase || type == .rulerLine || type == .rulerRect || type == .rulerPolygon || type == .areaRect || type == .areaPolygon {
                let newValue = strokeColor
                sublayers?.forEach({
                    if $0.name == SublayerName.value.rawValue {
                        ($0 as? CAShapeLayer)?.fillColor = newValue
                    } else if $0.name == SublayerName.fill.rawValue {
                        ($0 as? CAShapeLayer)?.fillColor = newValue
                    } else if $0.name == SublayerName.navi.rawValue {
                        ($0 as? CAShapeLayer)?.strokeColor = newValue
                        ($0 as? CAShapeLayer)?.fillColor = newValue
                    }
                })
            }
        }
    }

    override var lineWidth: CGFloat {
        didSet {
            let newValue = lineWidth
            sublayers?.forEach({
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.lineWidth = newValue / 2
                } else if $0.name == SublayerName.fill.rawValue {
                    ($0 as? CAShapeLayer)?.lineWidth = newValue
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.lineWidth = newValue
                }
            })
        }
    }
    
    private var laxness: CGFloat = 15
    
    override func removeFromSuperlayer() {
        if let layers = sublayers {
            for layer in layers {
                layer.removeFromSuperlayer()
            }
        }
        text = nil
        number = nil
        super.removeFromSuperlayer()
    }
    
    func draw() {
        if type == .line || type == .arrow {
            guard points.count == 1, points[0].count == 2 else {
                return
            }
            
            let path: UIBezierPath = UIBezierPath()
            path.move(to: points[0][0])
            path.addLine(to: points[0][1])
            
            if type == .arrow {
                var a: CGFloat = 0
                var b: CGFloat = 0
                var c: CGFloat = 0
                var c1: CGFloat = 0
                let bold: CGFloat = 3 * 4
                var point1: CGPoint = CGPoint.zero
                var point2: CGPoint = CGPoint.zero
                var point3: CGPoint = CGPoint.zero
                
                a = points[0][1].y - points[0][0].y
                b = points[0][1].x - points[0][0].x
                c = sqrt(pow(a, 2) + pow(b, 2))
                
                if b == 0, c == 0 {
                    return
                }
                var degree: CGFloat = acos(b / c)
                if a < 0 {
                    degree = -degree
                }
                
                point2.x = points[0][0].x + (c + bold * 0.8) * cos(degree)
                point2.y = points[0][0].y + (c + bold * 0.8) * sin(degree)
                
                c1 = sqrt(pow(c, 2) + pow(bold / 2, 2))
                
                let pointdegree: CGFloat = acos(c / c1)
                
                point1.x = points[0][0].x + (c1 - bold / 3) * cos(degree - pointdegree)
                point1.y = points[0][0].y + (c1 - bold / 3) * sin(degree - pointdegree)
                
                point3.x = points[0][0].x + (c1 - bold / 3) * cos(degree + pointdegree)
                point3.y = points[0][0].y + (c1 - bold / 3) * sin(degree + pointdegree)
                
                path.move(to: points[0][1])
                path.addLine(to: point3)
                path.addLine(to: point2)
                path.addLine(to: point1)
                path.addLine(to: points[0][1])
            }
            self.path = path.cgPath
            
        } else if type == .rect || type == .oval || type == .cross {
            guard points.count == 1, points[0].count == 4 else {
                return
            }
            
            let width: CGFloat = points[0][3].x - points[0][0].x
            let height: CGFloat = points[0][3].y - points[0][0].y
            
            let rect: CGRect = CGRect(x: points[0][0].x, y: points[0][0].y, width: width, height: height)
            
            if type == .rect {
                path = UIBezierPath(rect: rect).cgPath
            } else if type == .oval {
                path = UIBezierPath(ovalIn: rect).cgPath
            } else if type == .cross {
                let path: UIBezierPath = UIBezierPath()
                path.move(to: points[0][0])
                path.addLine(to: points[0][3])
                path.move(to: points[0][1])
                path.addLine(to: points[0][2])
                self.path = path.cgPath
            }
            
        } else if type == .freehand || type == .pen || type == .highlighter {
            
            let path: UIBezierPath = UIBezierPath()
            
            for i: Int in 0 ..< points.count {
                guard points[i].count > 1 else { continue }
                
                path.move(to: points[i][0])
                path.addLine(to: CGPoint(x: (points[i][0].x + points[i][1].x) / 2, y: (points[i][0].y + points[i][1].y) / 2))
                if points[i].count - 1 > 1 {
                    for j in 2 ..< points[i].count {
                        let middlePoint = CGPoint(x: (points[i][j - 1].x + points[i][j].x) / 2, y: (points[i][j - 1].y + points[i][j].y) / 2)
                        path.addQuadCurve(to: middlePoint, controlPoint: points[i][j - 1])
                    }
                }
                path.addLine(to: points[i][points[i].count - 1])
            }
            self.path = path.cgPath
            
        } else if type == .text {
            let origin = points[0][0]
            let width = points[0][1].x - points[0][0].x
            let height = points[0][1].y - points[0][0].y
            let frame = CGRect(x: origin.x, y: origin.y, width: width, height: height)
            let util = ObjcUtility()
            guard let textPath = util.bezierPath(text, rect: frame) else {
                return
            }
            path = textPath.cgPath
            
        } else if type == .rulerBase || type == .rulerLine {
            guard points.count == 1, points[0].count == 2 else {
                return
            }
            
            let a = Double((points[0][0].y - points[0][1].y) / (points[0][0].x - points[0][1].x))
            let b = Double(points[0][0].y - CGFloat(a) * points[0][0].x)
            
            let path = CGMutablePath()
            let distance = CGFloat(sqrt(pow(Double(points[0][0].x - points[0][1].x), 2) + pow(Double(points[0][0].y - points[0][1].y), 2)))
            var rad1 = atan2(points[0][0].y - points[0][1].y, points[0][0].x - points[0][1].x)
            if rad1 < 0 {
                rad1 = rad1 + CGFloat(Double.pi * 2)
            }
            let rad2 = rad1 + CGFloat(Double.pi) / 6
            
            let navigationHeight: CGFloat = 25 * lineWidth
            let fontSize: CGFloat = 20 * lineWidth
            
            let line = CGMutablePath()
            line.move(to: CGPoint(x: 0, y: -navigationHeight))
            line.addLine(to: CGPoint(x: 0, y: navigationHeight))
            let st = CGAffineTransform(translationX: points[0][0].x, y: points[0][0].y)
            var s1t = st.rotated(by: rad1)
            if let s1c = line.copy(using: &s1t) {
                path.addPath(s1c)
            }
            if type == .rulerBase {
                var s2t = st.rotated(by: rad2)
                if let s2c = line.copy(using: &s2t) {
                    path.addPath(s2c)
                }
            }
            let et = CGAffineTransform(translationX: points[0][1].x, y: points[0][1].y)
            var e1t = et.rotated(by: rad1)
            if let e1c = line.copy(using: &e1t) {
                path.addPath(e1c)
            }
            if type == .rulerBase {
                var e2t = et.rotated(by: rad2)
                if let e2c = line.copy(using: &e2t) {
                    path.addPath(e2c)
                }
            }
            
            let util = ObjcUtility()
            var txt = ""
            if type == .rulerBase {
                txt = ""
            } else {
                txt = number != nil ? "\(Double(number ?? 0.0))mm" : ""
            }
            
            let center = CGPoint(x: (points[0][0].x + points[0][1].x) / 2, y: (points[0][0].y + points[0][1].y) / 2)
            
            if let textPath = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath {
                var rad3 = rad1
                if CGFloat(Double.pi) / 2 <= rad3, rad3 <= CGFloat(Double.pi * (3 / 2)) {
                    rad3 += CGFloat(Double.pi)
                }
                if textPath.boundingBox.size.width + navigationHeight < distance {
                    var tt = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rad3)
                    if let cp = textPath.copy(using: &tt) {
                        sublayers?.forEach({
                            if $0.name == SublayerName.value.rawValue {
                                ($0 as? CAShapeLayer)?.path = cp
                            }
                        })
                    } else {
                        sublayers?.forEach({
                            if $0.name == SublayerName.value.rawValue {
                                ($0 as? CAShapeLayer)?.path = nil
                            }
                        })
                    }
                    let buff: CGFloat = 5 * lineWidth
                    let w = Double((distance - textPath.boundingBox.size.width) / 2 - buff)
                    var x1 = Double(points[0][0].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][0].x < points[0][1].x {
                        if x1 < Double(points[0][0].x) || Double(points[0][1].x) < x1 {
                            x1 = Double(points[0][0].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x1 < Double(points[0][1].x) || Double(points[0][0].x) < x1 {
                            x1 = Double(points[0][0].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y1 = a * x1 + b
                    var x2 = Double(points[0][1].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][0].x < points[0][1].x {
                        if x2 < Double(points[0][0].x) || Double(points[0][1].x) < x2 {
                            x2 = Double(points[0][1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x2 < Double(points[0][1].x) || Double(points[0][0].x) < x2 {
                            x2 = Double(points[0][1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y2 = a * x2 + b
                    
                    path.move(to: points[0][0])
                    path.addLine(to: CGPoint(x: x1, y: y1))
                    path.move(to: points[0][1])
                    path.addLine(to: CGPoint(x: x2, y: y2))
                    
                } else {
                    path.move(to: points[0][0])
                    path.addLine(to: points[0][1])
                    
                    let deg = floorf(Float(rad1) * (180 / Float.pi))
                    if deg.truncatingRemainder(dividingBy: Float(180)) == 0 {
                        var tt = CGAffineTransform(translationX: center.x, y: center.y - textPath.boundingBox.size.height).rotated(by: rad3)
                        if let cp = textPath.copy(using: &tt) {
                            sublayers?.forEach({
                                if $0.name == SublayerName.value.rawValue {
                                    ($0 as? CAShapeLayer)?.path = cp
                                }
                            })
                        } else {
                            sublayers?.forEach({
                                if $0.name == SublayerName.value.rawValue {
                                    ($0 as? CAShapeLayer)?.path = nil
                                }
                            })
                        }
                    } else {
                        let revA = -(1 / a)
                        let revB = Double(center.y) - revA * Double(center.x)
                        var x: Double = 0
                        if (CGFloat(Double.pi) / 2 <= rad1 && rad1 < CGFloat(Double.pi)) ||
                            (CGFloat(Double.pi * (3 / 2)) <= rad1 && rad1 < CGFloat(Double.pi * 2)) {
                            x = Double(center.x) - Double(textPath.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                        } else {
                            x = Double(center.x) + Double(textPath.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                        }
                        let y = revA * x + revB
                        var tt = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y)).rotated(by: rad3)
                        if let cp = textPath.copy(using: &tt) {
                            sublayers?.forEach({
                                if $0.name == SublayerName.value.rawValue {
                                    ($0 as? CAShapeLayer)?.path = cp
                                }
                            })
                        } else {
                            sublayers?.forEach({
                                if $0.name == SublayerName.value.rawValue {
                                    ($0 as? CAShapeLayer)?.path = nil
                                }
                            })
                        }
                    }
                }
            } else {
                path.move(to: points[0][0])
                path.addLine(to: points[0][1])
                
                sublayers?.forEach({
                    if $0.name == SublayerName.value.rawValue {
                        ($0 as? CAShapeLayer)?.path = nil
                    }
                })
            }
            
            self.path = path
            
        } else if type == .rulerRect {
            guard points.count == 1, points[0].count == 4 else {
                return
            }
            
            let path = CGMutablePath()
            let distance = CGFloat(sqrt(pow(Double(points[0][0].x - points[0][1].x), 2) + pow(Double(points[0][0].y - points[0][1].y), 2)))
            var rad1 = atan2(points[0][0].y - points[0][1].y, points[0][0].x - points[0][1].x)
            if rad1 < 0 {
                rad1 = rad1 + CGFloat(Double.pi * 2)
            }
            
            let navigationHeight: CGFloat = 25 * lineWidth
            let fontSize: CGFloat = 20 * lineWidth
            let rad = 3 * lineWidth / 2
            
            var textPathCP: CGPath?
            let nav = CGMutablePath()
            for i in 0 ..< 4 {
                nav.move(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y))
                nav.addLine(to: CGPoint(x: points[0][i].x, y: points[0][i].y - rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y))
                nav.addLine(to: CGPoint(x: points[0][i].x, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y))
            }
            
            let util = ObjcUtility()
            let txt = number != nil ? "\(Double(number ?? 0.0))mm" : ""
            
            var sp: CGPoint = .zero
            var ep: CGPoint = .zero
            if points[0][0].y < points[0][3].y {
                sp = points[0][0]
                ep = points[0][1]
            } else {
                sp = points[0][2]
                ep = points[0][3]
            }
            let center = CGPoint(x: (sp.x + ep.x) / 2, y: (sp.y + ep.y) / 2)
            
            let a = Double((sp.y - ep.y) / (sp.x - ep.x))
            let b = Double(sp.y - CGFloat(a) * sp.x)
            
            if let textPath = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath {
                var rad3 = rad1
                if CGFloat(Double.pi) / 2 <= rad3, rad3 <= CGFloat(Double.pi * (3 / 2)) {
                    rad3 += CGFloat(Double.pi)
                }
                let height = CGFloat(fabsf(Float(points[0][0].y - points[0][3].y)))
                if textPath.boundingBox.size.width + navigationHeight < distance, textPath.boundingBox.size.height / 2 + navigationHeight < height {
                    var tt = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rad3)
                    textPathCP = textPath.copy(using: &tt)
                    
                    let buff: CGFloat = 5 * lineWidth
                    let w = Double((distance - textPath.boundingBox.size.width) / 2 - buff)
                    var x1 = Double(sp.x) + w / sqrt(pow(a, 2) + 1)
                    if sp.x < ep.x {
                        if x1 < Double(sp.x) || Double(ep.x) < x1 {
                            x1 = Double(sp.x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x1 < Double(ep.x) || Double(sp.x) < x1 {
                            x1 = Double(sp.x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y1 = a * x1 + b
                    var x2 = Double(ep.x) + w / sqrt(pow(a, 2) + 1)
                    if sp.x < ep.x {
                        if x2 < Double(sp.x) || Double(ep.x) < x2 {
                            x2 = Double(ep.x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x2 < Double(ep.x) || Double(sp.x) < x2 {
                            x2 = Double(sp.x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y2 = a * x2 + b
                    
                    if points[0][0].y < points[0][3].y {
                        path.move(to: points[0][0])
                        path.addLine(to: CGPoint(x: x1, y: y1))
                        path.move(to: points[0][1])
                        path.addLine(to: CGPoint(x: x2, y: y2))
                        path.move(to: points[0][1])
                        path.addLine(to: points[0][3])
                        path.addLine(to: points[0][2])
                        path.addLine(to: points[0][0])
                    } else {
                        path.move(to: points[0][0])
                        path.addLine(to: points[0][1])
                        path.addLine(to: points[0][3])
                        path.addLine(to: CGPoint(x: x2, y: y2))
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: points[0][2])
                        path.addLine(to: points[0][0])
                    }
                    
                } else {
                    path.move(to: points[0][0])
                    path.addLine(to: points[0][1])
                    path.addLine(to: points[0][3])
                    path.addLine(to: points[0][2])
                    path.addLine(to: points[0][0])
                    
                    let deg = floorf(Float(rad1) * (180 / Float.pi))
                    if deg.truncatingRemainder(dividingBy: Float(180)) == 0 {
                        var tt = CGAffineTransform(translationX: center.x, y: center.y - textPath.boundingBox.size.height).rotated(by: rad3)
                        textPathCP = textPath.copy(using: &tt)
                        
                    } else {
                        let revA = -(1 / a)
                        let revB = Double(center.y) - revA * Double(center.x)
                        var x: Double = 0
                        if (CGFloat(Double.pi) / 2 <= rad1 && rad1 < CGFloat(Double.pi)) ||
                            (CGFloat(Double.pi * (3 / 2)) <= rad1 && rad1 < CGFloat(Double.pi * 2)) {
                            x = Double(center.x) - Double(textPath.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                        } else {
                            x = Double(center.x) + Double(textPath.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                        }
                        let y = revA * x + revB
                        var tt = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y)).rotated(by: rad3)
                        textPathCP = textPath.copy(using: &tt)
                    }
                }
            } else {
                path.move(to: points[0][0])
                path.addLine(to: points[0][1])
                path.addLine(to: points[0][3])
                path.addLine(to: points[0][2])
                path.addLine(to: points[0][0])
            }
            
            sublayers?.forEach({
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.path = textPathCP
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.path = nav
                }
            })
            
            self.path = path
            
        } else if type == .areaRect {
            guard points.count == 1, points[0].count == 4 else {
                return
            }
            
            let width: CGFloat = points[0][3].x - points[0][0].x
            let height: CGFloat = points[0][3].y - points[0][0].y

            let rect: CGRect = CGRect(x: points[0][0].x, y: points[0][0].y, width: width, height: height)
            
            let nav = CGMutablePath()
            var textPathCP: CGPath?
            var mask: CAShapeLayer?
            path = UIBezierPath(rect: rect).cgPath
            
            let fontSize: CGFloat = 20 * lineWidth
            let buff: CGFloat = 2 * lineWidth
            let rad = 3 * lineWidth / 2
            
            for i in 0 ..< 4 {
                nav.move(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y - rad))
                nav.addLine(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y - rad))
            }
            
            let util = ObjcUtility()
            let txt = number != nil ? "\(Double(number ?? 0.0))㎡" : ""
            
            let center = CGPoint(x: (points[0][0].x + points[0][3].x) / 2, y: (points[0][0].y + points[0][3].y) / 2)
            
            if let textPath = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath {
                var tt = CGAffineTransform(translationX: center.x, y: center.y)
                textPathCP = textPath.copy(using: &tt)
                
                if let textPathCP = textPathCP {
                    let maskPath = CGMutablePath()
                    if let cp = path {
                        maskPath.addPath(cp)
                    }
                    let rect = textPathCP.boundingBox
                    maskPath.addRect(CGRect(x: rect.origin.x - buff, y: rect.origin.y - buff, width: rect.size.width + buff * 2, height: rect.size.height + buff * 2))
                    mask = CAShapeLayer()
                    mask?.fillRule = CAShapeLayerFillRule.evenOdd
                    mask?.path = maskPath
                }
            }
            sublayers?.forEach({ [weak self] in
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.path = textPathCP
                } else if $0.name == SublayerName.fill.rawValue {
                    ($0 as? CAShapeLayer)?.path = self?.path
                    ($0 as? CAShapeLayer)?.mask = mask
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.path = nav
                }
            })
            
        } else if type == .rulerPolygon {
            guard points.count == 1 else {
                return
            }
            
            let util = ObjcUtility()
            
            let navigationHeight: CGFloat = 25 * lineWidth
            let fontSize: CGFloat = 20 * lineWidth
            let rad = 3 * lineWidth / 2
            var writed: Bool = false
            
            let txt = number != nil ? "\(Double(number ?? 0.0))mm" : ""
            
            let nav = CGMutablePath()
            let path = CGMutablePath()
            let textPath: CGPath? = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath
            var textPathCP: CGPath?
            
            nav.move(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y))
            nav.addLine(to: CGPoint(x: points[0][0].x, y: points[0][0].y - rad))
            nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y))
            nav.addLine(to: CGPoint(x: points[0][0].x, y: points[0][0].y + rad))
            nav.addLine(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y))
            
            path.move(to: points[0][0])
            for i in 1 ..< points[0].count {
                
                let distance = CGFloat(sqrt(pow(Double(points[0][i - 1].x - points[0][i].x), 2) + pow(Double(points[0][i - 1].y - points[0][i].y), 2)))
                var rad1 = atan2(points[0][i - 1].y - points[0][i].y, points[0][i - 1].x - points[0][i].x)
                if rad1 < 0 {
                    rad1 = rad1 + CGFloat(Double.pi * 2)
                }
                
                if let t = textPath, t.boundingBox.size.width + navigationHeight < distance, !writed {
                    writed = true
                    
                    let a = Double((points[0][i - 1].y - points[0][i].y) / (points[0][i - 1].x - points[0][i].x))
                    let b = Double(points[0][i - 1].y - CGFloat(a) * points[0][i - 1].x)
                    
                    var rad3 = rad1
                    if CGFloat(Double.pi) / 2 <= rad3, rad3 <= CGFloat(Double.pi * (3 / 2)) {
                        rad3 += CGFloat(Double.pi)
                    }
                    
                    let center = CGPoint(x: (points[0][i - 1].x + points[0][i].x) / 2, y: (points[0][i - 1].y + points[0][i].y) / 2)
                    
                    var tt = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rad3)
                    textPathCP = t.copy(using: &tt)
                    
                    let buff: CGFloat = 5 * lineWidth
                    let w = Double((distance - t.boundingBox.size.width) / 2 - buff)
                    var x1 = Double(points[0][i - 1].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][i - 1].x < points[0][i].x {
                        if x1 < Double(points[0][i - 1].x) || Double(points[0][i].x) < x1 {
                            x1 = Double(points[0][i - 1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x1 < Double(points[0][i].x) || Double(points[0][i - 1].x) < x1 {
                            x1 = Double(points[0][i - 1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y1 = a * x1 + b
                    var x2 = Double(points[0][i].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][i - 1].x < points[0][i].x {
                        if x2 < Double(points[0][i - 1].x) || Double(points[0][i].x) < x2 {
                            x2 = Double(points[0][i].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x2 < Double(points[0][i].x) || Double(points[0][i - 1].x) < x2 {
                            x2 = Double(points[0][i].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y2 = a * x2 + b
                    
                    path.move(to: points[0][i - 1])
                    path.addLine(to: CGPoint(x: x1, y: y1))
                    path.move(to: CGPoint(x: x2, y: y2))
                    path.addLine(to: points[0][i])
                } else {
                    path.addLine(to: points[0][i])
                }
                
                nav.move(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y))
                nav.addLine(to: CGPoint(x: points[0][i].x, y: points[0][i].y - rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y))
                nav.addLine(to: CGPoint(x: points[0][i].x, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y))
            }
            
            if name != "drawing", points[0].count > 2 {
                let distance = CGFloat(sqrt(pow(Double(points[0][points[0].count - 1].x - points[0][0].x), 2) + pow(Double(points[0][points[0].count - 1].y - points[0][0].y), 2)))
                var rad1 = atan2(points[0][points[0].count - 1].y - points[0][0].y, points[0][points[0].count - 1].x - points[0][0].x)
                if rad1 < 0 {
                    rad1 = rad1 + CGFloat(Double.pi * 2)
                }
                
                if let t = textPath, t.boundingBox.size.width + navigationHeight < distance, !writed {
                    writed = true
                    
                    let a = Double((points[0][points[0].count - 1].y - points[0][0].y) / (points[0][points[0].count - 1].x - points[0][0].x))
                    let b = Double(points[0][points[0].count - 1].y - CGFloat(a) * points[0][points[0].count - 1].x)
                    
                    var rad3 = rad1
                    if CGFloat(Double.pi) / 2 <= rad3, rad3 <= CGFloat(Double.pi * (3 / 2)) {
                        rad3 += CGFloat(Double.pi)
                    }
                    
                    let center = CGPoint(x: (points[0][points[0].count - 1].x + points[0][0].x) / 2, y: (points[0][points[0].count - 1].y + points[0][0].y) / 2)
                    
                    var tt = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rad3)
                    textPathCP = t.copy(using: &tt)
                    
                    let buff: CGFloat = 5 * lineWidth
                    let w = Double((distance - t.boundingBox.size.width) / 2 - buff)
                    var x1 = Double(points[0][points[0].count - 1].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][points[0].count - 1].x < points[0][0].x {
                        if x1 < Double(points[0][points[0].count - 1].x) || Double(points[0][0].x) < x1 {
                            x1 = Double(points[0][points[0].count - 1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x1 < Double(points[0][0].x) || Double(points[0][points[0].count - 1].x) < x1 {
                            x1 = Double(points[0][points[0].count - 1].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y1 = a * x1 + b
                    var x2 = Double(points[0][0].x) + w / sqrt(pow(a, 2) + 1)
                    if points[0][points[0].count - 1].x < points[0][0].x {
                        if x2 < Double(points[0][points[0].count - 1].x) || Double(points[0][0].x) < x2 {
                            x2 = Double(points[0][0].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    } else {
                        if x2 < Double(points[0][0].x) || Double(points[0][points[0].count - 1].x) < x2 {
                            x2 = Double(points[0][0].x) - w / sqrt(pow(a, 2) + 1)
                        }
                    }
                    let y2 = a * x2 + b
                    
                    path.move(to: points[0][points[0].count - 1])
                    path.addLine(to: CGPoint(x: x1, y: y1))
                    path.move(to: CGPoint(x: x2, y: y2))
                    path.addLine(to: points[0][0])
                } else {
                    path.addLine(to: points[0][0])
                }
            }
            
            if let t = textPath, !writed {
                let a = Double((points[0][0].y - points[0][1].y) / (points[0][0].x - points[0][1].x))
                let center = CGPoint(x: (points[0][0].x + points[0][1].x) / 2, y: (points[0][0].y + points[0][1].y) / 2)
                var rad1 = atan2(points[0][0].y - points[0][1].y, points[0][0].x - points[0][1].x)
                if rad1 < 0 {
                    rad1 = rad1 + CGFloat(Double.pi * 2)
                }
                var rad3 = rad1
                if CGFloat(Double.pi) / 2 <= rad3, rad3 <= CGFloat(Double.pi * (3 / 2)) {
                    rad3 += CGFloat(Double.pi)
                }
                
                let deg = floorf(Float(rad1) * (180 / Float.pi))
                if deg.truncatingRemainder(dividingBy: Float(180)) == 0 {
                    var tt = CGAffineTransform(translationX: center.x, y: center.y - t.boundingBox.size.height).rotated(by: rad3)
                    textPathCP = t.copy(using: &tt)
                    
                } else {
                    let revA = -(1 / a)
                    let revB = Double(center.y) - revA * Double(center.x)
                    var x: Double = 0
                    if (CGFloat(Double.pi) / 2 <= rad1 && rad1 < CGFloat(Double.pi)) ||
                        (CGFloat(Double.pi * (3 / 2)) <= rad1 && rad1 < CGFloat(Double.pi * 2)) {
                        x = Double(center.x) - Double(t.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                    } else {
                        x = Double(center.x) + Double(t.boundingBox.size.height) / sqrt(pow(revA, 2) + 1)
                    }
                    let y = revA * x + revB
                    var tt = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y)).rotated(by: rad3)
                    textPathCP = t.copy(using: &tt)
                }
            }
            
            sublayers?.forEach({
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.path = textPathCP
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.path = nav
                }
            })
            
            self.path = path
            
        } else if type == .areaPolygon {
            guard points.count == 1 else {
                return
            }
            
            let rad = 3 * lineWidth / 2
            
            var textPathCP: CGPath?
            var mask: CAShapeLayer?
            let path = CGMutablePath()
            let nav = CGMutablePath()
            
            nav.move(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y - rad))
            nav.addLine(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y + rad))
            nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y + rad))
            nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y - rad))
            
            path.move(to: points[0][0])
            for i in 1 ..< points[0].count {
                path.addLine(to: points[0][i])
                
                nav.move(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y - rad))
                nav.addLine(to: CGPoint(x: points[0][i].x - rad, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y + rad))
                nav.addLine(to: CGPoint(x: points[0][i].x + rad, y: points[0][i].y - rad))
            }
            
            if name != "drawing", points[0].count > 2 {
                path.addLine(to: points[0][0])
            }
            
            self.path = path
            
            let util = ObjcUtility()
            
            let fontSize: CGFloat = 20 * lineWidth
            let buff: CGFloat = 2 * lineWidth
            
            let txt = number != nil ? "\(Double(number ?? 0.0))㎡" : ""
            
            var gx: CGFloat = 0
            var gy: CGFloat = 0
            for i in 0 ..< points[0].count {
                gx += points[0][i].x
                gy += points[0][i].y
            }
            
            let center = CGPoint(x: gx / CGFloat(points[0].count), y: gy / CGFloat(points[0].count))
            if let textPath: CGPath = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath {
                var tt = CGAffineTransform(translationX: center.x, y: center.y)
                textPathCP = textPath.copy(using: &tt)
                
                if let textPathCP = textPathCP {
                    let maskPath = CGMutablePath()
                    if let cp = self.path {
                        maskPath.addPath(cp)
                    }
                    let rect = textPathCP.boundingBox
                    maskPath.addRect(CGRect(x: rect.origin.x - buff, y: rect.origin.y - buff, width: rect.size.width + buff * 2, height: rect.size.height + buff * 2))
                    mask = CAShapeLayer()
                    mask?.fillRule = CAShapeLayerFillRule.evenOdd
                    mask?.path = maskPath
                }
            }
            
            sublayers?.forEach({ [weak self] in
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.path = textPathCP
                } else if $0.name == SublayerName.fill.rawValue {
                    ($0 as? CAShapeLayer)?.path = self?.path
                    ($0 as? CAShapeLayer)?.mask = mask
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.path = nav
                }
            })
            
        } else if type == .rulerFreehand || type == .areaFreehand {
            guard !points[0].isEmpty else {
                return
            }
            
            var mask: CAShapeLayer?
            let path = CGMutablePath()
            var fill: CGPath?
            let nav = CGMutablePath()
            var textPathCP: CGPath?
            
            let fontSize: CGFloat = 20 * lineWidth
            let buff: CGFloat = 2 * lineWidth
            let rad = 3 * lineWidth / 2
            
            path.move(to: points[0][0])
            for i in 1 ..< points[0].count {
                path.addLine(to: points[0][i])
            }
            self.path = path
            
            if type == .areaFreehand {
                fill = path.copy(using: nil)
                
                nav.move(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y - rad))
                nav.addLine(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y + rad))
                nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y + rad))
                nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y - rad))
                
                if points[0].count > 1 {
                    nav.move(to: CGPoint(x: points[0][points[0].count - 1].x - rad, y: points[0][points[0].count - 1].y - rad))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x - rad, y: points[0][points[0].count - 1].y + rad))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x + rad, y: points[0][points[0].count - 1].y + rad))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x + rad, y: points[0][points[0].count - 1].y - rad))
                }
            } else {
                nav.move(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y))
                nav.addLine(to: CGPoint(x: points[0][0].x, y: points[0][0].y - rad))
                nav.addLine(to: CGPoint(x: points[0][0].x + rad, y: points[0][0].y))
                nav.addLine(to: CGPoint(x: points[0][0].x, y: points[0][0].y + rad))
                nav.addLine(to: CGPoint(x: points[0][0].x - rad, y: points[0][0].y))
                
                if points[0].count > 1 {
                    nav.move(to: CGPoint(x: points[0][points[0].count - 1].x - rad, y: points[0][points[0].count - 1].y))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x, y: points[0][points[0].count - 1].y - rad))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x + rad, y: points[0][points[0].count - 1].y))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x, y: points[0][points[0].count - 1].y + rad))
                    nav.addLine(to: CGPoint(x: points[0][points[0].count - 1].x - rad, y: points[0][points[0].count - 1].y))
                }
            }
            
            let util = ObjcUtility()
            let unit = type == .rulerFreehand ? "mm" : "㎡"
            let txt = number != nil ? "\(Double(number ?? 0.0))\(unit)" : ""
            
            var gx: CGFloat = 0
            var gy: CGFloat = 0
            for i in 0 ..< points[0].count {
                gx += points[0][i].x
                gy += points[0][i].y
            }
            
            let center = CGPoint(x: gx / CGFloat(points[0].count), y: gy / CGFloat(points[0].count))
            if let textPath: CGPath = util.singleLineStringBezierPath(txt, fontSize: fontSize)?.cgPath {
                var tt = CGAffineTransform(translationX: center.x, y: center.y)
                textPathCP = textPath.copy(using: &tt)
                
                if let textPathCP = textPathCP, type == .areaFreehand {
                    let maskPath = CGMutablePath()
                    if let cp = self.path {
                        maskPath.addPath(cp)
                    }
                    let rect = textPathCP.boundingBox
                    maskPath.addRect(CGRect(x: rect.origin.x - buff, y: rect.origin.y - buff, width: rect.size.width + buff * 2, height: rect.size.height + buff * 2))
                    mask = CAShapeLayer()
                    mask?.fillRule = CAShapeLayerFillRule.evenOdd
                    mask?.path = maskPath
                }
            }
            
            sublayers?.forEach({
                if $0.name == SublayerName.value.rawValue {
                    ($0 as? CAShapeLayer)?.path = textPathCP
                } else if $0.name == SublayerName.fill.rawValue {
                    ($0 as? CAShapeLayer)?.path = fill
                    ($0 as? CAShapeLayer)?.mask = mask
                } else if $0.name == SublayerName.navi.rawValue {
                    ($0 as? CAShapeLayer)?.path = nav
                }
            })
        }
    }
    
    func navigationLayer() ->PaintLayer? {
        let naviColor = UIColor(red: 100 / 255, green: 149 / 255, blue: 237 / 255, alpha: 1)
        if type == .text {
            let navi = PaintLayer()
            navi.strokeColor = UIColor.clear.cgColor
            navi.fillColor = naviColor.cgColor
            navi.path = path
            
            let sub = CAShapeLayer()
            sub.name = SublayerName.navi.rawValue
            sub.strokeColor = naviColor.cgColor
            sub.fillColor = UIColor.clear.cgColor
            
            let x = points[0][0].x
            let y = points[0][0].y
            let width = points[0][1].x - points[0][0].x
            let height = points[0][1].y - points[0][0].y
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + width, y: y))
            path.addLine(to: CGPoint(x: x + width, y: y + height))
            path.addLine(to: CGPoint(x: x, y: y + height))
            path.close()
            
            sub.path = path.cgPath.copy()
            
            navi.addSublayer(sub)
            
            return navi
            
        } else {
            
            let navi = PaintLayer()
            navi.strokeColor = naviColor.cgColor
            navi.fillColor = UIColor.clear.cgColor
            
            let path = CGMutablePath()
            
            if type == .arrow {
                path.move(to: points[0][0])
                path.addLine(to: points[0][1])
                
            } else {
                if let p = self.path?.copy() {
                    path.addPath(p)
                }
                
                if let layers = sublayers {
                    for layer in layers {
                        if let p = (layer as? CAShapeLayer)?.path?.copy() {
                            path.addPath(p)
                        }
                    }
                }
            }
            
            navi.path = path
            
            return navi
        }
    }
    
    func drawingData(contentsSize: CGSize, contentsScale: CGFloat) -> (category: Int, type: Int, properties: String, path: String)? {
        guard let strokeCGColor = strokeColor, let fillCGColor = fillColor else {
            return nil
        }
        
        var category: Int = 0
        var type: Int = 0
        var properties: String = ""
        var path: String = ""
        let w: CGFloat = baseLineWidth / contentsSize.height * 1000
        
        var strokeColor = "sc=\(UIColor(cgColor: strokeCGColor).toHexString().uppercased())"
        var fillColor = "fc=\(UIColor(cgColor: fillCGColor).toHexString().uppercased())"
        let lineWidth = "w=\(w)"
        var lineCap = "lc="
        if self.lineCap == CAShapeLayerLineCap.round {
            lineCap += "r"
        } else if self.lineCap == CAShapeLayerLineCap.square {
            lineCap += "s"
        } else {
            // CAShapeLayerLineCap.butt
            lineCap += "b"
        }
        let opacity = "o=\(self.opacity)"
        
        if self.type == .line || self.type == .arrow || self.type == .oval || self.type == .rect || self.type == .cross {
            
            category = 3
            
            let point0 = CGPoint(x: points[0][0].x / contentsSize.width * 1000.0, y: points[0][0].y / contentsSize.height * 1000.0)
            let point1 = CGPoint(x: points[0][1].x / contentsSize.width * 1000.0, y: points[0][1].y / contentsSize.height * 1000.0)
            
            if self.type == .line || self.type == .arrow {
                if self.type == .line {
                    type = 5
                    properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
                } else {
                    type = 2
                    properties = "\(strokeColor),\(fillColor),\(lineWidth),\(lineCap),\(opacity)"
                }
                
                path = "\(point0.x),\(point0.y)|\(point1.x),\(point1.y)"
                
            } else {
                let point2 = CGPoint(x: points[0][2].x / contentsSize.width * 1000.0, y: points[0][2].y / contentsSize.height * 1000.0)
                let point3 = CGPoint(x: points[0][3].x / contentsSize.width * 1000.0, y: points[0][3].y / contentsSize.height * 1000.0)
                
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
                
                let width = point3.x - point0.x
                let height = point3.y - point0.y
                
                if self.type == .rect {
                    type = 3
                    path = "\(point0.x),\(point0.y),\(width),\(height)"
                    
                } else if self.type == .oval {
                    type = 4
                    
                    let rx = width / 2
                    let ry = height / 2
                    
                    let cx = point0.x + rx
                    let cy = point0.y + ry
                    
                    path = "\(cx),\(cy),\(rx),\(ry)"
                    
                } else {
                    type = 6
                    
                    // 0-3/1-2
                    path = "\(point0.x),\(point0.y)|\(point3.x),\(point3.y)\n\(point1.x),\(point1.y)|\(point2.x),\(point2.y)"
                }
            }
            
            return (category, type, properties, path)
            
        } else if self.type == .freehand || self.type == .pen || self.type == .highlighter {
            category = 2
            if self.type == .highlighter {
                type = 2
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
            } else {
                type = 1
                properties = "\(strokeColor),\(lineWidth),\(lineCap)"
            }
            
            for i in 0 ..< points.count {
                for j in 0 ..< points[i].count {
                    let x: CGFloat = points[i][j].x / contentsSize.width * 1000
                    let y: CGFloat = points[i][j].y / contentsSize.height * 1000
                    path += "\(x),\(y)"
                    
                    if j < points[i].count - 1 {
                        path += "|"
                    }
                }
                path += "\n"
            }
            
            return (category, type, properties, path)
            
        } else if self.type == .text {
            guard let text = text, !text.string.isEmpty else {
                return nil
            }

            category = 4
            type = 1
            
            let attributes = text.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: text.length))
            guard let font = attributes[NSAttributedString.Key.font] as? UIFont else {
                return nil
            }
            strokeColor = "sc=\(UIColor(cgColor: self.fillColor!).toHexString().uppercased())"
            let fontSize = "fs=\(font.pointSize / contentsSize.height * 1000)"
            properties = "\(strokeColor),\(fontSize)"
            
            let x = points[0][0].x / contentsSize.width * 1000
            let y = points[0][0].y / contentsSize.height * 1000
            let width = (points[0][1].x - points[0][0].x) / contentsSize.width * 1000
            let height = (points[0][1].y - points[0][0].y) / contentsSize.height * 1000
            
            path = "\(x),\(y),\(ceilf(Float(width))),\(ceilf(Float(height))),\(contentsSize.width),\(contentsSize.height),\(text.string)"
            
            return (category, type, properties, path)
            
        } else if self.type == .rulerBase || self.type == .rulerLine {
            category = 5
            
            let x1 = points[0][0].x / contentsSize.width * 1000
            let y1 = points[0][0].y / contentsSize.height * 1000
            let x2 = points[0][1].x / contentsSize.width * 1000
            let y2 = points[0][1].y / contentsSize.height * 1000
           
            // とりあえずここを直す
            if self.type == .rulerBase {
                type = 1
                path = "\(strokeColor.replace(target: "sc=", withString: ""))|\(lineWidth.replace(target: "w=", withString: ""))|\(lineCap.replace(target: "lc=", withString: ""))|\(opacity.replace(target: "o=", withString: ""))|\(x1),\(y1)|\(x2),\(y2)|\(Double(number ?? 0.0))"
            } else {
                type = 2
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
                path = "\(x1),\(y1)|\(x2),\(y2)"
            }
            
            return (category, type, properties, path)
            
        } else if self.type == .rulerRect || self.type == .areaRect {
            category = 5
            
            if self.type == .rulerRect {
                type = 3
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
            } else {
                type = 6
                fillColor = "fc=\(UIColor(cgColor: self.strokeColor!).toHexString().uppercased())"
                properties = "\(strokeColor),\(fillColor),\(lineWidth),\(lineCap),\(opacity)"
            }
            
            let point0 = CGPoint(x: points[0][0].x / contentsSize.width * 1000.0, y: points[0][0].y / contentsSize.height * 1000.0)
            let point3 = CGPoint(x: points[0][3].x / contentsSize.width * 1000.0, y: points[0][3].y / contentsSize.height * 1000.0)
            
            let width = point3.x - point0.x
            let height = point3.y - point0.y
            
            path = "\(point0.x),\(point0.y),\(width),\(height)"
            
            return (category, type, properties, path)
            
        } else if self.type == .rulerPolygon || self.type == .areaPolygon || self.type == .rulerFreehand || self.type == .areaFreehand {
            category = 5
            
            if self.type == .rulerPolygon {
                type = 10
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
            } else if self.type == .areaPolygon {
                type = 7
                fillColor = "fc=\(UIColor(cgColor: self.strokeColor!).toHexString().uppercased())"
                properties = "\(strokeColor),\(fillColor),\(lineWidth),\(lineCap),\(opacity)"
            } else if self.type == .rulerFreehand {
                type = 5
                properties = "\(strokeColor),\(lineWidth),\(lineCap),\(opacity)"
            } else if self.type == .areaFreehand {
                type = 9
                fillColor = "fc=\(UIColor(cgColor: self.strokeColor!).toHexString().uppercased())"
                properties = "\(strokeColor),\(fillColor),\(lineWidth),\(lineCap),\(opacity)"
            }
            
            for i in 0 ..< points[0].count {
                let x: CGFloat = points[0][i].x / contentsSize.width * 1000
                let y: CGFloat = points[0][i].y / contentsSize.height * 1000
                path += "\(x),\(y)"
                
                if i < points[0].count - 1 {
                    path += "|"
                }
            }
            
            return (category, type, properties, path)
            
        }
        
        return nil
    }
    
    func shouldSaveLayer() -> Bool {
        if type == .freehand || type == .pen || type == .highlighter {
            return points.count >= 1 && points[0].count > 1
            
        } else if type == .arrow || type == .line || type == .rulerBase || type == .rulerLine {
            return points.count == 1 && points[0].count == 2 && "\(points[0][0])" != "\(points[0][1])"
            
        } else if type == .rect || type == .oval || type == .cross || type == .rulerRect || type == .areaRect {
            return points.count == 1 && points[0].count == 4 && "\(points[0][0])" != "\(points[0][3])"
            
        } else if type == .rulerPolygon {
            return points.count == 1 && points[0].count > 1
            
        } else if type == .areaPolygon {
            return points.count == 1 && points[0].count > 2
            
        } else if type == .rulerFreehand {
            return points.count == 1 && points[0].count > 1
            
        } else if type == .areaFreehand {
            return points.count == 1 && points[0].count > 2
            
        }
        
        return false
    }

    func paintObject() -> PaintObject {
        return PaintObject(
            identifier: identifier,
            type: type,
            points: points,
            text: text,
            number: number,
            strokeColor: strokeColor,
            fillColor: fillColor,
            baseLineWidth: baseLineWidth,
            lineWidth: lineWidth,
            opacity: opacity,
            operation: operation)
    }
    
    func copyLayer() -> PaintLayer {
        let layer = PaintLayer()
        layer.identifier = identifier
        layer.type = type
        layer.points = points
        layer.text = text
        layer.strokeColor = strokeColor
        layer.fillColor = fillColor
        layer.baseLineWidth = baseLineWidth
        layer.lineWidth = lineWidth
        layer.opacity = opacity
        layer.operation = operation
        layer.number = number
        return layer
    }
    
    func isTouch(_ point: CGPoint, zoomScale: CGFloat = 1) -> Bool {
        guard let path = self.path else {
            return super.contains(point)
        }
        let laxness = self.laxness / zoomScale
        let copyPath = path.copy(strokingWithWidth: laxness * 2,
                                 lineCap: .butt,
                                 lineJoin: .bevel,
                                 miterLimit: 0)
        
        // is tap line
        if copyPath.contains(point) {
            return true
        }
        // is tap line of subLayers
        if type == .rulerBase || type == .rulerLine || type == .rulerRect || type == .rulerPolygon || type == .rulerFreehand ||
            type == .areaRect || type == .areaPolygon || type == .areaFreehand {
            if (sublayers?.filter {
                ($0 as? CAShapeLayer)?.path?.copy(strokingWithWidth: laxness * 2,
                                                  lineCap: .butt,
                                                  lineJoin: .bevel,
                                                  miterLimit: 0).contains(point) == true
            }.count ?? 0) > 0 {
                return true
            }
        }
        // is tap inside object
        if type == .areaRect || type == .areaPolygon || type == .areaFreehand {
            return path.contains(point, using: .evenOdd, transform: CGAffineTransform.identity)
        }
        
        return false
    }
}

final class PaintUndoObject: NSObject {
    
    internal var operation: String = "" // N:vẽ hình mới,U:cập nhật,D: xoá hình
    internal var paintObjects: [PaintObject]!
    
    deinit {
        operation = ""
        paintObjects = nil
    }
}

final class PaintObject: NSObject {
    
    let identifier: String
    let type: PaintView.PaintType
    let points: [[CGPoint]]
    let text: NSAttributedString?
    // Add new number element to save value from layer
    let number: Double?
    let strokeColor: CGColor?
    let fillColor: CGColor?
    let baseLineWidth: CGFloat
    let lineWidth: CGFloat
    let opacity: Float
    var operation: PaintLayer.Operation
    
    // check if type is ruler
    var typeIsRulers: Bool {
        switch type {
        case .rulerBase:
            return true
        case .areaFreehand,
             .areaPolygon,
             .areaRect,
             .arrow,
             .colors,
             .cross,
             .default,
             .figureBase,
             .freehand,
             .highlighter,
             .line,
             .oval,
             .pen,
             .rect,
             .rulerFreehand,
             .rulerLine,
             .rulerPolygon,
             .rulerRect,
             .rulers,
             .selectRect,
             .text:
            return false
        }
    }
    
    init(identifier: String,
         type: PaintView.PaintType,
         points: [[CGPoint]],
         text: NSAttributedString?,
         number: Double?,
         strokeColor: CGColor?,
         fillColor: CGColor?,
         baseLineWidth: CGFloat,
         lineWidth: CGFloat,
         opacity: Float,
         operation: PaintLayer.Operation) {
        self.identifier = identifier
        self.type = type
        self.points = points
        self.text = text
        self.number = number
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.baseLineWidth = baseLineWidth
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.operation = operation
    }
    
    // check is rulerBase with Operation is New or Delete
    func checkIsRulerBaseWithNewOrDelete() -> Bool {
        return type == .rulerBase && operation == .new || type == .rulerBase && operation == .delete
    }

}
