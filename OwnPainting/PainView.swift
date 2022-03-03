//
//  PainView.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

protocol PaintViewOldDelegate: AnyObject {
    func didSelectLayer()
    func didDeSelectLayer()
}

protocol PaintViewDelegate: AnyObject {
    func paintView(_ paintView: PaintView, didSelectLayers: [PaintLayer])
    func paintView(_ paintView: PaintView, didDeSelectLayers: [PaintLayer])
    func paintView(_ paintView: PaintView, isTouchLayers: [PaintLayer])
    func paintView(_ paintView: PaintView, didChangeUndoStack: [PaintUndoObject])
    func paintView(_ paintView: PaintView, didChangeRedoStack: [PaintUndoObject])
    
    func paintView(_ paintView: PaintView, didChangePainObject: PaintObject)
    
    func paintView(_ paintView: PaintView, willDisplayLoupe layer: PaintLayer, point: CGPoint)
    func paintView(_ paintView: PaintView, willMoveLoupe layer: PaintLayer, point: CGPoint)
    func paintView(_ paintView: PaintView, didDeDisplayLoupe layer: PaintLayer)
    
    func paintView(_ paintView: PaintView, didEndDrawing layers: [PaintLayer])
    
    func paintView(_ paintView: PaintView, didEndDrawing layer: PaintLayer, error: PaintView.PaintError)
}

final class PaintView: UIView {
    
    enum PaintError: Error {
        case `default`
        case hasIntersectionPolygon
    }
    
    enum PaintType: Int {
        case `default`
        case selectRect
        case arrow
        case freehand
        case pen
        case highlighter
        case text
        case figureBase
        case line
        case rect
        case oval
        case cross
        case rulers
        case rulerBase
        case rulerLine
        case rulerRect
        case rulerPolygon
        case rulerFreehand
        case areaRect
        case areaPolygon
        case areaFreehand
        case colors
    }
    
    private enum RectType: Int {
        case rect
        case oval
    }
    
    weak var oldDelegate: PaintViewOldDelegate? {
        willSet {
            isOld = false
        }
        didSet {
            if oldDelegate != nil {
                isOld = true
                delegate = nil
            }
        }
    }
    weak var delegate: PaintViewDelegate? {
        didSet {
            if delegate != nil {
                oldDelegate = nil
            }
        }
    }
    private var isOld: Bool = false
    
    private let dateUtil = DateUtil()
    // TODO: Presenterに移動
    
    internal var paintType: PaintType = .freehand
    internal var drawingObjects: DrawingObject? {
        didSet {
            guard let drawingObjects = drawingObjects else {
                return
            }
            for object in drawingObjects.shapes {
                let layer = PaintLayer()
                layer.identifier = object.id
                switch object.type {
                case .ellipse:
                    layer.type = .oval
                    guard let a = object.a, let b = object.b else { return }
                    guard a.count == 2, b.count == 2 else { return }
                    let point0 = CGPoint(x: a[0], y: a[1])
                    let point1 = CGPoint(x: b[0], y: a[1])
                    let point2 = CGPoint(x: a[0], y: b[1])
                    let point3 = CGPoint(x: b[0], y: b[1])
                    layer.points[0].append(point0)
                    layer.points[0].append(point1)
                    layer.points[0].append(point2)
                    layer.points[0].append(point3)
                    layer.strokeColor = UIColor(hexString1: object.strokeColor!).cgColor
                    layer.fillColor = UIColor(hexString1: object.fillColor!).cgColor
                    layer.lineWidth = CGFloat(object.strokeWidth ?? 5)
                    layer.baseLineWidth = 5
                    
                    
                case .freehand:
                    layer.type = .freehand
                    guard let segments = object.segments, let strokeColor = object.strokeColor, let lineWidth = object.strokeWidth else { return }
                    for (index, segment) in segments.enumerated() {
                        if index == 0 {
                            let point1 = CGPoint(x: segment.a[0], y: segment.a[1])
                            let point2 = CGPoint(x: segment.b[0], y: segment.b[1])
                            layer.points[0].append(point1)
                            layer.points[0].append(point2)

                        } else {
                            let point = CGPoint(x: segment.b[0], y: segment.b[1])
                            layer.points[0].append(point)

                        }
                    }
                    layer.lineWidth = CGFloat(lineWidth)
                    layer.strokeColor = UIColor(hexString1: strokeColor).cgColor
                    layer.fillColor = UIColor.clear.cgColor
                    layer.baseLineWidth = 5
                    print("start pen")
                case .text:
                    guard let boundingRect = object.boundingRect, boundingRect.count == 2 else { return }
                    layer.type = .text
//                    layer.fillColor = UIColor(hexString1: object.fillColor ?? ).cgColor
                    let text = object.text
                    let fontSize = object.fontSize
                    guard let x = boundingRect[0][0],
                          let y = boundingRect[0][1],
                          let width = boundingRect[1][0],
                          let height = boundingRect[1][1] else { return }
                    layer.points[0].append(CGPoint(x: x, y: y))
                    layer.points[0].append(CGPoint(x: x + width, y: y + height))
                    let style = NSMutableParagraphStyle()
                    style.alignment = .left
                    style.lineBreakMode = .byCharWrapping
                    let strokeColor = UIColor.clear.cgColor


                    let dict: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.paragraphStyle: style,
                        NSAttributedString.Key.kern: 0.0,
                        NSAttributedString.Key.font:  UIFont.systemFont(ofSize: CGFloat(fontSize ?? 0)),
                        NSAttributedString.Key.foregroundColor: strokeColor
                    ]
                    layer.text = NSAttributedString(string: text ?? "", attributes: dict)
                    print("add Text")

                }
                layer.draw()
                self.layer.addSublayer(layer)
            }
        }
    }
    internal var paintColor: UIColor = UIColor.red {
        didSet {
            guard let layers = selectLayers else {
                return
            }
            
            let undo = PaintUndoObject()
            undo.operation = "U"
            undo.paintObjects = []
            
            for layer in layers {
                undo.paintObjects.append(layer.paintObject())
                
                // 色の変更
                if layer.type == .text {
                    layer.strokeColor = UIColor.clear.cgColor
                    layer.fillColor = paintColor.cgColor
                    
                    var attributes = layer.text?.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: layer.text?.length ?? 0)) ?? [:]
                    attributes[NSAttributedString.Key.foregroundColor] = paintColor
                    layer.text = NSAttributedString(string: layer.text?.string ?? "", attributes: attributes)
                } else {
                    layer.strokeColor = paintColor.cgColor
                    if layer.type == .arrow {
                        layer.fillColor = paintColor.cgColor
                    } else {
                        layer.fillColor = UIColor.clear.cgColor
                    }
                }
            }
            
            if !undo.paintObjects.isEmpty {
                undoStack.insert(undo, at: 0)
                redoStack = []
            }
        }
    }
    internal var lineWidth: CGFloat = 5 {
        didSet {
            guard let layers = selectLayers else {
                return
            }
            
            let undo = PaintUndoObject()
            undo.operation = "U"
            undo.paintObjects = []
            
            for layer in layers {
                undo.paintObjects.append(layer.paintObject())
                
                // 線の変更
                layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScale
            }
            
            if !undo.paintObjects.isEmpty {
                undoStack.insert(undo, at: 0)
                redoStack = []
            }
            
            drawSelectNavigations(isRedraw: false)
        }
    }
    internal var contentsScale: CGFloat = 1
    internal var zoomScale: CGFloat = 1 {
        didSet {
            guard delegate != nil else {
                return
            }
            if let sublayers = layer.sublayers {
                for layer in sublayers {
                    guard let layer = layer as? PaintLayer else { continue }
                    if layer.type == .pen || layer.type == .arrow || layer.type == .line || layer.type == .rect || layer.type == .oval || layer.type == .cross {
                        layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                    } else if layer.type == .rulerBase || layer.type == .rulerLine || layer.type == .rulerRect || layer.type == .rulerPolygon || layer.type == .rulerFreehand || layer.type == .areaRect || layer.type == .areaPolygon || layer.type == .areaFreehand {
                        layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                        layer.draw()
                    }
                }
            }
        }
    }
    internal var zoomScaleOffset: CGFloat {
        var scale = zoomScale
        if zoomScale < minimumZoomScale {
            scale = minimumZoomScale
        } else if zoomScale > 1 {
            scale = 1
        }
        return scale
    }
    internal var minimumZoomScale: CGFloat = 1
    internal var maximumZoomScale: CGFloat = 1
    
    internal var shouldSave: Bool {
        if !trashBox.isEmpty {
            return true
        }
        if let subLayers = layer.sublayers?.compactMap({ $0 as? PaintLayer }) {
            if !subLayers.filter({ $0.operation == .new }).isEmpty || !subLayers.filter({ $0.operation == .edit }).isEmpty {
                return true
            }
        }
        return false
    }
    
    private let drawing: String = "drawing"
    private let selecting: String = "selecting"
    private let navigation: String = "navigation"
    
    // move
    private var isMoved: Bool = false
    private var firstTouchPoint: [[CGPoint]]?
    private var lastTouchPoint: CGPoint?
    
    // freehand
    private var isFirstMoved: Bool = false
    private var freehandCompletedTimer: Timer?
    
    // undo・redo
    private var undoStack: [PaintUndoObject] = [] {
        didSet {
            if undoStack.count != oldValue.count {
                delegate?.paintView(self, didChangeUndoStack: undoStack)
            }
        }
    }
    private var redoStack: [PaintUndoObject] = [] {
        didSet {
            if redoStack.count != oldValue.count {
                delegate?.paintView(self, didChangeRedoStack: redoStack)
            }
        }
    }
    private var trashBox: [String: PaintObject] = [:]
    
    // text
    weak var textManagementView: PaintTextManagementView? {
        willSet {
            textManagementView?.paintView = nil
        }
        didSet {
            textManagementView?.paintView = self
        }
    }
    
    private var isDrawing: Bool = false
    
    private let measuringUtil: MeasuringUtil = MeasuringUtil()
    
    private var drawingLayer: PaintLayer? {
        return drawingLayers?.first
    }
    
    private var drawingLayers: [PaintLayer]? {
        let name = drawing
        return layer.sublayers?.filter({ $0.name == name }).compactMap({ $0 as? PaintLayer })
    }
    
    internal var selectLayers: [PaintLayer]? {
        let name = selecting
        return layer.sublayers?.filter({ $0.name == name }).compactMap({ $0 as? PaintLayer })
    }
    
    private var navigationLayers: [PaintLayer]? {
        let name = navigation
        return layer.sublayers?.filter({ $0.name == name }).compactMap({ $0 as? PaintLayer })
    }
    
    private var navigationViews: [PaintSelectNavigationView] {
        return subviews.compactMap({ $0 as? PaintSelectNavigationView })
    }
    
    internal var measuringBaseLayer: PaintLayer? {
        return layer.sublayers?.compactMap({
            if let layer = $0 as? PaintLayer, layer.type == .rulerBase {
                return layer
            } else {
                return nil
            }
        }).first
    }
    
    private var measuringLayers: [PaintLayer]? {
        return layer.sublayers?.compactMap({
            if let layer = $0 as? PaintLayer {
                if layer.type == .rulerLine || layer.type == .rulerRect || layer.type == .rulerPolygon || layer.type == .rulerFreehand ||
                    layer.type == .areaRect || layer.type == .areaPolygon || layer.type == .areaFreehand {
                    return layer
                }
            }
            return nil
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
    }
    
    override func removeFromSuperview() {
        textManagementView = nil
        
        for view in subviews {
            view.removeFromSuperview()
        }
        if let layerCount = layer.sublayers?.count {
            for i in (0 ..< layerCount).reversed() {
                layer.sublayers?[i].removeFromSuperlayer()
            }
        }
        super.removeFromSuperview()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = location(touches: touches, with: event) else {
            return
        }
        if let points = isTouchLayers(point: point)?.first?.points {
            firstTouchPoint = points
        }
        isFirstMoved = false
        isMoved = false
        lastTouchPoint = nil
        
        if paintType == .default {
            if isOld {
                removeSelectNavigations()
                
                selectLayer(point: point)
                
                if let layers = selectLayers, !layers.isEmpty {
                    drawSelectNavigations()
                    
                    oldDelegate?.didSelectLayer()
                    
                    lastTouchPoint = point
                    isFirstMoved = true
                } else {
                    oldDelegate?.didDeSelectLayer()
                }
                
            } else {
                if let oldLayers = selectLayers, !oldLayers.isEmpty {
                    let oldIds = oldLayers.map({ $0.identifier })
                    if let newLayers = isTouchLayers(point: point), !newLayers.isEmpty {
                        if newLayers.count == 1 {
                            lastTouchPoint = point
                            isFirstMoved = true
                            
                            select(layer: newLayers[0])
                        } else if !newLayers.filter({ oldIds.contains($0.identifier) }).isEmpty {
                            lastTouchPoint = point
                            isFirstMoved = true
                        } else {
                            cancelSelectLayers()
                            delegate?.paintView(self, isTouchLayers: newLayers)
                        }
                    } else {
                        cancelSelectLayers()
                    }
                } else {
                    if let newLayers = isTouchLayers(point: point), !newLayers.isEmpty {
                        if newLayers.count == 1 {
                            lastTouchPoint = point
                            isFirstMoved = true
                            
                            select(layer: newLayers[0])
                        } else {
                            cancelSelectLayers()
                            delegate?.paintView(self, isTouchLayers: newLayers)
                        }
                    } else {
                        cancelSelectLayers()
                    }
                }
            }
        } else {
            if paintType == .rulerPolygon || paintType == .areaPolygon {
                isFirstMoved = true
            }
            paint(point: point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = location(touches: touches, with: event) else {
            return
        }
        
        isMoved = true
        
        if paintType == .default {
            if isOld {
                if let layers = selectLayers, !layers.isEmpty {
                    // 移動+再描画
                    move(point: point)
                    drawSelectNavigations()
                }
                
            } else {
                if let layers = selectLayers, !layers.isEmpty {
                    // 移動+再描画
                    move(point: point)
                    drawSelectNavigations()
                }
            }

        } else {
            paint(point: point)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            isMoved = false
            lastTouchPoint = nil
            isFirstMoved = false
            firstTouchPoint = nil
        }
        guard let point = location(touches: touches, with: event) else {
            return
        }
        
        if paintType == .default {
            if isOld {
                if let layers = selectLayers, !layers.isEmpty {
                    // 移動+再描画
                    if isMoved {
                        isFirstMoved = false
                    }
                    move(point: point)
                    drawSelectNavigations()
                }
            } else {
                // 移動+再描画
                if isMoved {
                    isFirstMoved = false
                }
                move(point: point)
                drawSelectNavigations()
                
                if let layers = selectLayers {
                    if layers.count == 1 {
                        delegate?.paintView(self, didSelectLayers: layers)
                    }
                }
            }
            
        } else {
            if let layer = drawingLayer {
                if paintType == .rulerBase || paintType == .rulerLine ||
                    paintType == .rulerRect || paintType == .rulerPolygon || paintType == .rulerFreehand ||
                    paintType == .areaRect || paintType == .areaPolygon || paintType == .areaFreehand {
                    delegate?.paintView(self, didDeDisplayLoupe: layer)
                }
                // 描画完了処理
                paint(point: point)
                
                if paintType == .freehand || paintType == .pen {
                    freehandCompletedTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(freehandCompleted(_:)), userInfo: nil, repeats: true)
                } else if !(paintType == .rulerPolygon || paintType == .areaPolygon) {
                    endPaint()
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            isMoved = false
            lastTouchPoint = nil
            isFirstMoved = false
        }
        if let point = location(touches: touches, with: event) {
            if paintType == .default {
                if isOld {
                    if let layers = selectLayers, !layers.isEmpty {
                        // 移動+再描画
                        move(point: point)
                        drawSelectNavigations()
                    }
                } else {
                    // 移動+再描画
                    move(point: point)
                    drawSelectNavigations()
                    
                    if let layers = selectLayers {
                        if layers.count == 1 {
                            delegate?.paintView(self, didSelectLayers: layers)
                        }
                    }
                }
                
            } else {
                if let layer = drawingLayer {
                    if paintType == .rulerBase || paintType == .rulerLine ||
                        paintType == .rulerRect || paintType == .rulerPolygon || paintType == .rulerFreehand ||
                        paintType == .areaRect || paintType == .areaPolygon || paintType == .areaFreehand {
                        delegate?.paintView(self, didDeDisplayLoupe: layer)
                    }
                    // 描画完了処理
                
                    if paintType == .freehand || paintType == .pen {
                        freehandCompletedTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(freehandCompleted(_:)), userInfo: nil, repeats: true)
                    } else if !(paintType == .rulerPolygon || paintType == .areaPolygon) {
                        endPaint()
                    }
                }
            }
        } else {
            if let layer = drawingLayer {
                if paintType == .rulerBase || paintType == .rulerLine ||
                    paintType == .rulerRect || paintType == .rulerPolygon || paintType == .rulerFreehand ||
                    paintType == .areaRect || paintType == .areaPolygon || paintType == .areaFreehand {
                    delegate?.paintView(self, didDeDisplayLoupe: layer)
                }
                if !(paintType == .rulerPolygon || paintType == .areaPolygon) {
                    endPaint()
                }
            }
        }
    }
    
//    func set(display: PlanContentsDisplayObject) {
//        guard let layers = layer.sublayers else {
//            return
//        }
//        for layer in layers {
//            guard let layer = layer as? PaintLayer else { continue }
//            layer.isHidden = display.drawing.isHidden(layer: layer)
//        }
//    }
    
    func select(layer: PaintLayer) {
        self.layer.sublayers?.forEach({ [weak self] in
            if ($0 as? PaintLayer)?.identifier == layer.identifier {
                $0.name = self?.selecting
            } else if $0.name != self?.navigation {
                $0.name = ""
            }
        })
        
        drawSelectNavigations()
        
        if let layers = selectLayers {
            delegate?.paintView(self, didSelectLayers: layers)
        }
    }
    
    func cancelSelectLayers() {
        
        var isCancelSelect = false
        let name = selecting
        layer.sublayers?.forEach({
            if $0.name == name {
                $0.name = ""
                isCancelSelect = true
            }
        })
        removeSelectNavigations()
        
        oldDelegate?.didDeSelectLayer()
        if isCancelSelect {
            delegate?.paintView(self, didDeSelectLayers: [])
        }
    }
    
    func removeSelectLayers() {
        removeSelectNavigations()
        
        guard let layers = selectLayers else {
            return
        }
        
        let undo = PaintUndoObject()
        undo.operation = "D"
        undo.paintObjects = []
        
        var isCalcMeasure: Bool = false
        
        for layer in layers {
            isCalcMeasure = layer.type == .rulerBase
            if layer.operation != .new {
                trashBox[layer.identifier] = layer.paintObject()
            }
            layer.operation = .delete
            undo.paintObjects.append(layer.paintObject())
            layer.removeFromSuperlayer()
        }
        if isCalcMeasure {
            calcMeasuring()
        }
        if !undo.paintObjects.isEmpty {
            undoStack.insert(undo, at: 0)
            redoStack = []
        }
    }
    
    func editSelectTextLayer() {
        removeSelectNavigations()
        
        guard let layer = selectLayers?.first, layer.type == .text else {
            return
        }
        guard let frame = layer.path?.boundingBox else {
            return
        }
        layer.path = nil
        
        textManagementView?.editText(layer: layer, frame: frame)
    }
    
    func reinitialize() {
        defer {
            reinitializeUndo()
        }
        
        guard let sublayers = layer.sublayers else {
            return
        }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    private func reinitializeUndo() {
        undoStack = []
        redoStack = []
        trashBox = [:]
    }
    
    func removeAllLayers() {
        cancelSelectLayers()
        
        guard let layers = layer.sublayers?.compactMap({ $0 as? PaintLayer }) else {
            return
        }
        
        let undo = PaintUndoObject()
        undo.operation = "D"
        undo.paintObjects = []
        
        for layer in layers {
            if layer.operation != .new {
                trashBox[layer.identifier] = layer.paintObject()
            }
            undo.paintObjects.append(layer.paintObject())
            layer.removeFromSuperlayer()
        }
        if !undo.paintObjects.isEmpty {
            undoStack.insert(undo, at: 0)
            redoStack = []
        }
    }
    
    func undo() {
        cancelSelectLayers()
        guard !undoStack.isEmpty else {
            return
        }
        
        let undo = undoStack.remove(at: 0)
        guard let firstObject = undo.paintObjects.first else {
            return
        }
        // add action for change measure menu
        delegate?.paintView(self, didChangePainObject: firstObject)
        var lengthPerPx: Double?
        if let base = measuringBaseLayer, let lpp = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
            lengthPerPx = lpp
        }
        
        switch undo.operation {
        case "N":
            let redo = PaintUndoObject()
            redo.operation = "N"
            redo.paintObjects = []
            
            defer {
                if !redo.paintObjects.isEmpty {
                    redoStack.insert(redo, at: 0)
                }
            }
            
            guard let layers = layer.sublayers else {
                return
            }
            for layer in layers {
                if let l = layer as? PaintLayer, l.identifier == firstObject.identifier {
                    l.operation = firstObject.operation
                    redo.paintObjects.append(l.paintObject())
                    layer.removeFromSuperlayer()
                    calcMeasuring()
                    return
                }
            }
            
        case "U":
            guard let layers = layer.sublayers else {
                return
            }
            let redo = PaintUndoObject()
            redo.operation = "U"
            redo.paintObjects = []
            
            defer {
                if !redo.paintObjects.isEmpty {
                    redoStack.insert(redo, at: 0)
                }
            }
            
            for undo in undo.paintObjects {
                let pLayers = layers.filter({ (layer: CALayer) -> Bool in
                    if let l = layer as? PaintLayer, l.identifier == undo.identifier {
                        return true
                    } else {
                        return false
                    }
                })
                
                for pLayer in pLayers {
                    guard let layer = pLayer as? PaintLayer else { continue }
                    if let paintObjectCurent = measuringBaseLayer?.paintObject(), layer.type == .rulerBase {
                        paintObjectCurent.operation = undo.operation
                        redo.paintObjects.append(paintObjectCurent)
                    } else {
                        layer.operation = undo.operation
                        redo.paintObjects.append(layer.paintObject())
                    }
                    
                    layer.strokeColor = undo.strokeColor
                    layer.fillColor = undo.fillColor
                    if layer.type == .highlighter {
                        layer.lineWidth = layer.baseLineWidth
                    } else {
                        layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                    }
                    layer.baseLineWidth = undo.baseLineWidth
                    layer.points = undo.points
                    layer.text = undo.text
                    layer.opacity = undo.opacity
                    layer.operation = undo.operation
                    
//                    if layer.type != .rulerBase {
                    if let lpp = lengthPerPx, layer.type != .rulerBase {
                        if layer.type == .rulerLine {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else if layer.type == .rulerRect {
                            layer.number = measuringUtil.length(
                                rect: CGRect(
                                    x: layer.points[0][0].x,
                                    y: layer.points[0][0].y,
                                    width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                    height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                                ),
                                lengthPerPx: lpp
                            )
                        } else if layer.type == .areaRect {
                            layer.number = measuringUtil.area(
                                rect: CGRect(
                                    x: layer.points[0][0].x,
                                    y: layer.points[0][0].y,
                                    width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                    height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                                ),
                                lengthPerPx: lpp
                            )
                        } else if layer.type == .rulerPolygon {
                            if layer.name == drawing {
                                layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                            } else {
                                layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lpp)
                            }
                        } else if layer.type == .rulerFreehand {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else if layer.type == .areaPolygon || layer.type == .areaFreehand {
                            layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lpp)
                        }
                        layer.draw()
                    } else {
                        // process if redo have number -> save to layer
                        if let number = undo.number {
                            layer.number = number
                            layer.draw()
                            calcMeasuring()
                        } else {
                            layer.number = nil
                            layer.draw()
                        }
                    }
                    
                }
            }
            
        case "D":
            let redo = PaintUndoObject()
            redo.operation = "D"
            redo.paintObjects = []
            
            defer {
                if !redo.paintObjects.isEmpty {
                    redoStack.insert(redo, at: 0)
                }
            }
            
            for undo in undo.paintObjects {
                redo.paintObjects.append(undo)
                
                let layer = PaintLayer()
                layer.identifier = undo.identifier
                layer.type = undo.type
                layer.strokeColor = undo.strokeColor
                layer.fillColor = undo.fillColor
                layer.baseLineWidth = undo.baseLineWidth
                if layer.type == .highlighter {
                    layer.lineWidth = layer.baseLineWidth
                } else {
                    layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                }
                layer.points = undo.points
                layer.text = undo.text
                layer.opacity = undo.opacity
                layer.operation = undo.operation
                if layer.type == .freehand {
                    layer.lineCap = CAShapeLayerLineCap.round
                }
                
                if let lpp = lengthPerPx {
                    if layer.type == .rulerLine {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                    } else if layer.type == .rulerRect {
                        layer.number = measuringUtil.length(
                            rect: CGRect(
                                x: layer.points[0][0].x,
                                y: layer.points[0][0].y,
                                width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                            ),
                            lengthPerPx: lpp
                        )
                    } else if layer.type == .areaRect {
                        layer.number = measuringUtil.area(
                            rect: CGRect(
                                x: layer.points[0][0].x,
                                y: layer.points[0][0].y,
                                width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                            ),
                            lengthPerPx: lpp
                        )
                    } else if layer.type == .rulerPolygon {
                        if layer.name == drawing {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else {
                            layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lpp)
                        }
                    } else if layer.type == .rulerFreehand {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                    } else if layer.type == .areaPolygon || layer.type == .areaFreehand {
                        layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lpp)
                    }
                } else {
                    // process if redo have number -> save to layer
                    if let number = undo.number {
                        layer.number = number
                    } else {
                        layer.number = nil
                    }
                }
                
                layer.draw()
                self.layer.addSublayer(layer)
                calcMeasuring()
                trashBox[layer.identifier] = nil
            }
            
        default:
            break
        }
    }
    
    func redo() {
        cancelSelectLayers()
        guard !redoStack.isEmpty else {
            return
        }
        
        let redo = redoStack.remove(at: 0)
        guard let firstObject = redo.paintObjects.first else {
            return
        }
        // add action for change status measure menu
        delegate?.paintView(self, didChangePainObject: firstObject)
        var lengthPerPx: Double?
        if let base = measuringBaseLayer, let lpp = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
            lengthPerPx = lpp
        }
        
        switch redo.operation {
        case "N":
            let undo = PaintUndoObject()
            undo.operation = "N"
            undo.paintObjects = []
            
            defer {
                if !undo.paintObjects.isEmpty {
                    undoStack.insert(undo, at: 0)
                }
            }
            
            for redo in redo.paintObjects {
                undo.paintObjects.append(redo)
                
                let layer = PaintLayer()
                layer.identifier = redo.identifier
                layer.type = redo.type
                layer.strokeColor = redo.strokeColor
                layer.fillColor = redo.fillColor
                layer.baseLineWidth = redo.baseLineWidth
                if layer.type == .highlighter {
                    layer.lineWidth = layer.baseLineWidth
                } else {
                    layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                }
                layer.points = redo.points
                layer.text = redo.text
                layer.opacity = redo.opacity
                layer.operation = redo.operation
                if layer.type == .freehand {
                    layer.lineCap = CAShapeLayerLineCap.round
                }
                
                if let lpp = lengthPerPx {
                    if layer.type == .rulerLine {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                    } else if layer.type == .rulerRect {
                        layer.number = measuringUtil.length(
                            rect: CGRect(
                                x: layer.points[0][0].x,
                                y: layer.points[0][0].y,
                                width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                            ),
                            lengthPerPx: lpp
                        )
                    } else if layer.type == .areaRect {
                        layer.number = measuringUtil.area(
                            rect: CGRect(
                                x: layer.points[0][0].x,
                                y: layer.points[0][0].y,
                                width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                            ),
                            lengthPerPx: lpp
                        )
                    } else if layer.type == .rulerPolygon {
                        if layer.name == drawing {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else {
                            layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lpp)
                        }
                    } else if layer.type == .rulerFreehand {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                    } else if layer.type == .areaPolygon || layer.type == .areaFreehand {
                        layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lpp)
                    }
                    layer.draw()
                    self.layer.addSublayer(layer)
                } else {
                    // process if redo have number -> save to layer
                    if let number = redo.number {
                        layer.number = number
                        layer.draw()
                        self.layer.addSublayer(layer)
                        calcMeasuring()
                    } else {
                        layer.number = nil
                        layer.draw()
                        self.layer.addSublayer(layer)
                    }
                }
                
            }
            
        case "U":
            let undo = PaintUndoObject()
            undo.operation = "U"
            undo.paintObjects = []
            
            defer {
                if !undo.paintObjects.isEmpty {
                    undoStack.insert(undo, at: 0)
                }
            }
            
            guard let layers = layer.sublayers else {
                return
            }
            for redo in redo.paintObjects {
                let pLayers = layers.filter({ (layer: CALayer) -> Bool in
                    if let l = layer as? PaintLayer, l.identifier == redo.identifier {
                        return true
                    } else {
                        return false
                    }
                })
                
                for pLayer in pLayers {
                    guard let layer = pLayer as? PaintLayer else { continue }
                    layer.operation = redo.operation
                    undo.paintObjects.append(layer.paintObject())
                    
                    layer.strokeColor = redo.strokeColor
                    layer.fillColor = redo.fillColor
                    layer.baseLineWidth = redo.baseLineWidth
                    if layer.type == .highlighter {
                        layer.lineWidth = layer.baseLineWidth
                    } else {
                        layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
                    }
                    layer.points = redo.points
                    layer.text = redo.text
                    layer.opacity = redo.opacity
                    
                    if let lpp = lengthPerPx, layer.type != .rulerBase {
                        if layer.type == .rulerLine {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else if layer.type == .rulerRect {
                            layer.number = measuringUtil.length(
                                rect: CGRect(
                                    x: layer.points[0][0].x,
                                    y: layer.points[0][0].y,
                                    width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                    height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                                ),
                                lengthPerPx: lpp
                            )
                        } else if layer.type == .areaRect {
                            layer.number = measuringUtil.area(
                                rect: CGRect(
                                    x: layer.points[0][0].x,
                                    y: layer.points[0][0].y,
                                    width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                                    height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                                ),
                                lengthPerPx: lpp
                            )
                        } else if layer.type == .rulerPolygon {
                            if layer.name == drawing {
                                layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                            } else {
                                layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lpp)
                            }
                        } else if layer.type == .rulerFreehand {
                            layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                        } else if layer.type == .areaPolygon || layer.type == .areaFreehand {
                            layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lpp)
                        }
                        layer.draw()
                    } else {
                        // process if redo have number -> save to layer
                        if let number = redo.number {
                            layer.number = number
                            layer.draw()
                            calcMeasuring()
                        } else {
                            layer.number = nil
                            layer.draw()
                        }
                    }
                }
            }
            
        case "D":
            let undo = PaintUndoObject()
            undo.operation = "D"
            undo.paintObjects = []
            
            defer {
                if !undo.paintObjects.isEmpty {
                    undoStack.insert(undo, at: 0)
                }
            }
            
            guard let layers = layer.sublayers else {
                return
            }
            for layer in layers {
                if let l = layer as? PaintLayer, l.identifier == firstObject.identifier {
                    trashBox[l.identifier] = l.paintObject()
                    l.operation = firstObject.operation
                    undo.paintObjects.append(l.paintObject())
                    layer.removeFromSuperlayer()
                    calcMeasuring()
                    return
                }
            }
            
        default:
            break
        }
    }
    
    func set(measuringBaseLength: Double?) {
        if let length = measuringBaseLength {
            if length != measuringBaseLayer?.number {
                guard let layers = selectLayers else {
                    return
                }
                let undo = PaintUndoObject()
                undo.operation = "U"
                undo.paintObjects = []
                for layer in layers {
                    let newLayer = layer.copyLayer()
                    newLayer.operation = .edit
                    undo.paintObjects.append(newLayer.paintObject())
                }
                if !undo.paintObjects.isEmpty {
                    undoStack.insert(undo, at: 0)
                    redoStack = []
                }
            }
            measuringBaseLayer?.number = length
            measuringBaseLayer?.draw()
        } else {
            if measuringBaseLayer?.number == nil {
                measuringBaseLayer?.removeFromSuperlayer()
            }
        }
        drawSelectNavigations(isRedraw: true)
        calcMeasuring()
    }
    
    private func paint(point: CGPoint) {
        
        switch paintType {
        case .freehand,
             .highlighter,
             .pen:
            freehand(point: point)
        case .line:
            line(point: point)
        case .arrow:
            line(point: point, isArrow: true)
        case .rect:
            rect(point: point)
        case .oval:
            rect(point: point, type: .oval)
        case .cross:
            rect(point: point, type: .oval)
        case .text:
            textManagementView?.addText(point: point, textColor: paintColor)
        case .rulerBase,
             .rulerLine:
            measure(point: point)
        case .areaRect,
             .rulerRect:
            measureRect(point: point)
        case .areaPolygon,
             .rulerPolygon:
            measurePolygon(point: point)
        case .areaFreehand,
             .rulerFreehand:
            measureFreehand(point: point)
        default:
            break
        }
    }
    
    func endPaint() {
        guard let layers: [PaintLayer] = drawingLayers else {
            return
        }
        
        delegate?.paintView(self, didEndDrawing: layers)
        
        for layer in layers {
            for i in (0 ..< layer.points.count).reversed() {
                if layer.points[i].count <= 1 {
                    layer.points.remove(at: i)
                }
            }
            if layer.shouldSaveLayer() {
                layer.name = nil
                if layer.type == .highlighter {
                    layer.opacity = 0.3
                } else {
                    layer.opacity = 1
                }
                if layer.type == .rulerPolygon {
                    if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                        layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lengthPerPx)
                    } else {
                        layer.number = nil
                    }
                    layer.draw()
                } else if layer.type == .areaPolygon {
                    if measuringUtil.hasIntersection(points: layer.points[0]) {
                        layer.removeFromSuperlayer()
                        delegate?.paintView(self, didEndDrawing: layer, error: .hasIntersectionPolygon)
                        continue
                    } else {
                        if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                            layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lengthPerPx)
                        } else {
                            layer.number = nil
                        }
                        layer.draw()
                    }
                }
                
                let undo = PaintUndoObject()
                undo.operation = "N"
                undo.paintObjects = [layer.paintObject()]
                undoStack.insert(undo, at: 0)
                redoStack = []
                
            } else {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    private func endPolygonPaint() {
        guard let layer = drawingLayer else {
            return
        }
        if measuringUtil.hasIntersection(points: layer.points[0]) {
            layer.points[0].removeLast()
            layer.draw()
            
            delegate?.paintView(self, didEndDrawing: layer, error: .hasIntersectionPolygon)
        }
    }
    
    // 自由入力
    private func freehand(point: CGPoint) {
        if let layer = drawingLayer {
            
            if freehandCompletedTimer?.isValid == true {
                freehandCompletedTimer?.invalidate()
                
                layer.opacity = 0.3
                isFirstMoved = true
                layer.points.append([])
                
            } else if isFirstMoved {
                isFirstMoved = false
                return
            }
            freehandCompletedTimer = nil
            
            layer.points[layer.points.count - 1].append(point)
            
            layer.draw()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            layer.strokeColor = paintColor.cgColor
            layer.fillColor = UIColor.clear.cgColor
            if paintType == .pen {
                layer.type = .pen
                layer.baseLineWidth = 1
                layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            } else if paintType == .highlighter {
                layer.type = .highlighter
                layer.baseLineWidth = 10 * contentsScale / zoomScale
                layer.lineWidth = layer.baseLineWidth
            } else {
                layer.type = .freehand
                layer.lineWidth = lineWidth * contentsScale
                layer.baseLineWidth = lineWidth
            }
            layer.name = drawing
            if paintType == .highlighter {
                layer.opacity = 0.3
            } else {
                if isOld {
                    layer.opacity = 0.3
                } else {
                    layer.opacity = 0.6
                }
            }
            layer.lineCap = CAShapeLayerLineCap.round
            
            isFirstMoved = true
            
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
        }
    }
    
    @objc private func freehandCompleted(_ timer: Timer) {
        if let layers = drawingLayers, let base = layers.first {
            
            let opacity = base.opacity + 0.01
            for layer in layers {
                layer.opacity = opacity
            }
            
            if opacity >= 1 {
                endPaint()
                freehandCompletedTimer?.invalidate()
                freehandCompletedTimer = nil
            }
        } else {
            freehandCompletedTimer?.invalidate()
            freehandCompletedTimer = nil
        }
    }
    
    func invalidateFreehandCompletedTimer() {
        if let layers = drawingLayers {
            
            for layer in layers {
                layer.opacity = 1
            }
            
            endPaint()
            freehandCompletedTimer?.invalidate()
            freehandCompletedTimer = nil
        } else {
            endPaint()
            freehandCompletedTimer?.invalidate()
            freehandCompletedTimer = nil
        }
    }
    
    // 線・矢印
    private func line(point: CGPoint, isArrow: Bool = false) {
        if let layer = drawingLayer {
            
            if layer.points[0].count > 1 {
                layer.points[0][1] = point
            } else {
                layer.points[0].append(point)
            }
            
            layer.draw()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            if isArrow {
                layer.type = .arrow
                layer.fillColor = paintColor.cgColor
            } else {
                layer.type = .line
                layer.fillColor = UIColor.clear.cgColor
            }
            layer.strokeColor = paintColor.cgColor
            layer.baseLineWidth = lineWidth
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
        }
    }
    
    // 矩形・円・バツ
    private func rect(point: CGPoint, type: RectType = .rect) {
        if let layer = drawingLayer {
            
            if layer.points[0].count > 1 {
                layer.points[0][1].x = point.x
                layer.points[0][2].y = point.y
                layer.points[0][3] = point
            } else {
                layer.points[0].append(point)
                layer.points[0].append(point)
                layer.points[0].append(point)
            }
            
            layer.draw()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            switch type {
            case .rect:
                layer.type = .rect
            case .oval:
                layer.type = .oval
            }
            layer.strokeColor = paintColor.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.baseLineWidth = lineWidth
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            
            layer.points[0].append(point)
            layer.points[0].append(point)
            layer.points[0].append(point)
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
        }
    }
    
    // 計測（線）
    private func measure(point: CGPoint) {
        if let layer = drawingLayer {
            
            if layer.points[0].count > 1 {
                layer.points[0][1] = point
            } else {
                layer.points[0].append(point)
            }
            
            if layer.type == .rulerBase {
                calcMeasuring()
                
            } else if layer.type == .rulerLine {
                if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                    layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lengthPerPx)
                }
            }
            
            layer.draw()
            
            delegate?.paintView(self, willMoveLoupe: layer, point: layer.points[0][1])
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            if paintType == .rulerBase {
                layer.type = .rulerBase
            } else if paintType == .rulerLine {
                layer.type = .rulerLine
            }
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = paintColor.cgColor
            layer.baseLineWidth = 1
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            
            layer.points[0].append(point)
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
            
            delegate?.paintView(self, willDisplayLoupe: layer, point: layer.points[0][1])
        }
    }
    
    // 計測（矩形）
    private func measureRect(point: CGPoint) {
        if let layer = drawingLayer {
            
            if layer.points[0].count > 1 {
                layer.points[0][1].x = point.x
                layer.points[0][2].y = point.y
                layer.points[0][3] = point
            } else {
                layer.points[0].append(point)
                layer.points[0].append(point)
                layer.points[0].append(point)
            }
            
            if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                if layer.type == .rulerRect {
                    layer.number = measuringUtil.length(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lengthPerPx
                    )
                } else if layer.type == .areaRect {
                    layer.number = measuringUtil.area(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lengthPerPx
                    )
                }
            } else {
                layer.number = nil
            }
            
            layer.draw()
            
            delegate?.paintView(self, willMoveLoupe: layer, point: layer.points[0][3])
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            layer.type = paintType
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = paintColor.cgColor
            layer.baseLineWidth = 1
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            
            layer.points[0].append(point)
            layer.points[0].append(point)
            layer.points[0].append(point)
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
            
            delegate?.paintView(self, willDisplayLoupe: layer, point: layer.points[0][3])
        }
    }
    
    // 計測（多角形）
    private func measurePolygon(point: CGPoint) {
        if let layer = drawingLayer {
            
            if isFirstMoved || layer.points.isEmpty {
                layer.points[0].append(point)
                isFirstMoved = false
                
                delegate?.paintView(self, willDisplayLoupe: layer, point: layer.points[0][layer.points[0].count - 1])
            } else {
                layer.points[0][layer.points[0].count - 1] = point
                
                delegate?.paintView(self, willMoveLoupe: layer, point: layer.points[0][layer.points[0].count - 1])
            }
            
            if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                if layer.type == .rulerPolygon {
                    layer.number = measuringUtil.length(points: layer.points[0], isClose: false, lengthPerPx: lengthPerPx)
                }
            } else {
                layer.number = nil
            }
            
            layer.draw()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            layer.type = paintType
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = paintColor.cgColor
            layer.baseLineWidth = 1
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            
            layer.points[0].append(point)
            isFirstMoved = false
            
            layer.draw()
            self.layer.addSublayer(layer)
            
            delegate?.paintView(self, willDisplayLoupe: layer, point: layer.points[0][layer.points[0].count - 1])
        }
    }
    
    // 計測（自由線）
    private func measureFreehand(point: CGPoint) {
        if let layer = drawingLayer {
            
            if isFirstMoved {
                isFirstMoved = false
                return
            }
            
            layer.points[layer.points.count - 1].append(point)
            delegate?.paintView(self, willMoveLoupe: layer, point: layer.points[0][layer.points[0].count - 1])
            
            if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                if layer.type == .rulerFreehand {
                    layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lengthPerPx)
                } else if layer.type == .areaFreehand {
                    layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lengthPerPx)
                }
            } else {
                layer.number = nil
            }
            
            layer.draw()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = "N\(dateUtil.getJSTDateString(.DateTimeWithMilliSec_NonSeparate))"
            layer.strokeColor = paintColor.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.type = paintType
            layer.baseLineWidth = 1
            layer.lineWidth = layer.baseLineWidth * contentsScale / zoomScaleOffset
            layer.name = drawing
            layer.lineCap = CAShapeLayerLineCap.round
            
            isFirstMoved = true
            
            layer.points[0].append(point)
            
            layer.draw()
            self.layer.addSublayer(layer)
            
            delegate?.paintView(self, willDisplayLoupe: layer, point: layer.points[0][layer.points[0].count - 1])
        }
    }
    
    // テキスト
    func text(_ text: String, attributes: [NSAttributedString.Key: Any], layer_id: String, rect: CGRect) {
        guard let textColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor else {
            return
        }
        let textRect = NSString(string: text).boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        if let layers = selectLayers?.filter({ $0.identifier == layer_id }), !layers.isEmpty {
            if layers.count == 1 {
                let undo = PaintUndoObject()
                undo.operation = "U"
                undo.paintObjects = [layers[0].paintObject()]
                undoStack.insert(undo, at: 0)
                redoStack = []
                
                layers[0].strokeColor = UIColor.clear.cgColor
                layers[0].fillColor = textColor.cgColor
                
                layers[0].text = NSAttributedString(string: text, attributes: attributes)
                layers[0].points[0][0] = rect.origin
                layers[0].points[0][1] = CGPoint(x: rect.origin.x + textRect.size.width, y: rect.origin.y + textRect.size.height)
                
                layers[0].draw()
            }
            cancelSelectLayers()
            
        } else {
            let layer = PaintLayer()
            layer.operation = .new
            layer.identifier = layer_id
            layer.type = .text
            layer.strokeColor = UIColor.clear.cgColor
            layer.fillColor = textColor.cgColor
            
            layer.text = NSAttributedString(string: text, attributes: attributes)
            layer.points[0].append(rect.origin)
            layer.points[0].append(CGPoint(x: rect.origin.x + textRect.size.width, y: rect.origin.y + textRect.size.height))
            
            layer.draw()
            
            self.layer.addSublayer(layer)
            
            let undo = PaintUndoObject()
            undo.operation = "N"
            undo.paintObjects = [layer.paintObject()]
            undoStack.insert(undo, at: 0)
            redoStack = []
        }
    }
}

// MARK: - PaintSelectNavigationViewDelegate
extension PaintView: PaintSelectNavigationViewDelegate {
    
    func willMove(point: PaintSelectNavigationView.Point) {
        guard let layers = selectLayers else {
            return
        }
        let undo: PaintUndoObject = PaintUndoObject()
        undo.operation = "U"
        undo.paintObjects = []
        
        for layer in layers {
            if layer.type == .rulerBase {
                layer.operation = .edit
            }
            undo.paintObjects.append(layer.paintObject())
            if layer.operation != .new {
                layer.operation = .edit
            }
        }
        if !undo.paintObjects.isEmpty {
            undoStack.insert(undo, at: 0)
            redoStack = []
        }
        
        guard let layer = layers.first else {
            return
        }
        if layer.type == .rulerBase || layer.type == .rulerLine || layer.type == .rulerRect || layer.type == .rulerPolygon || layer.type == .areaRect || layer.type == .areaPolygon {
            var p: CGPoint?
            switch point {
            case .start:
                p = layer.points[0][0]
            case .end:
                p = layer.points[0][1]
            case .upperLeft:
                p = layer.points[0][0]
            case .upperRight:
                p = layer.points[0][1]
            case .bottomLeft:
                p = layer.points[0][2]
            case .bottomRight:
                p = layer.points[0][3]
            case .general(let i):
                p = layer.points[0][i]
            default:
                break
            }
            guard let point = p else {
                return
            }
            delegate?.paintView(self, willDisplayLoupe: layer, point: point)
        }
    }
    
    func didMove(point: PaintSelectNavigationView.Point, delta: CGPoint) {
        guard let layer = selectLayers?.first else {
            return
        }
        
        if layer.type == .line || layer.type == .arrow {
            
            switch point {
            case .start:
                layer.points[0][0].x += delta.x
                layer.points[0][0].y += delta.y
                
            case .end:
                layer.points[0][1].x += delta.x
                layer.points[0][1].y += delta.y
                
            default:
                break
            }
            layer.draw()
            
        } else if layer.type == .rect || layer.type == .oval || layer.type == .cross {
            
            switch point {
            case .upperLeft:
                layer.points[0][0].x += delta.x
                layer.points[0][0].y += delta.y
                layer.points[0][1].y += delta.y
                layer.points[0][2].x += delta.x
                
            case .upperRight:
                layer.points[0][0].y += delta.y
                layer.points[0][1].x += delta.x
                layer.points[0][1].y += delta.y
                layer.points[0][3].x += delta.x
                
            case .bottomLeft:
                layer.points[0][0].x += delta.x
                layer.points[0][2].x += delta.x
                layer.points[0][2].y += delta.y
                layer.points[0][3].y += delta.y
                
            case .bottomRight:
                layer.points[0][1].x += delta.x
                layer.points[0][2].y += delta.y
                layer.points[0][3].x += delta.x
                layer.points[0][3].y += delta.y
                
            default:
                break
            }
            
            layer.draw()
            
        } else if layer.type == .freehand || layer.type == .pen || layer.type == .highlighter || layer.type == .rulerFreehand || layer.type == .areaFreehand {
            guard let rect = layer.path?.boundingBox else {
                return
            }
            
            var x: CGFloat = delta.x
            var y: CGFloat = delta.y
            let spacing: CGFloat = 50
            
            switch point {
            case .upperLeft:
                
                if rect.maxX - rect.minX == 0 || (x >= 0 && rect.minX + x + spacing >= rect.maxX) {
                    x = 1
                } else {
                    x = 1 - x / (rect.maxX - rect.minX)
                }
                if rect.maxY - rect.minY == 0 || (y >= 0 && rect.minY + y + spacing >= rect.maxY) {
                    y = 1
                } else {
                    y = 1 - y / (rect.maxY - rect.minY)
                }
                
                for i: Int in 0 ..< layer.points.count {
                    for j: Int in 0 ..< layer.points[i].count {
                        layer.points[i][j] = CGPoint(x: rect.maxX - (rect.maxX - layer.points[i][j].x) * x, y: rect.maxY - (rect.maxY - layer.points[i][j].y) * y)
                    }
                }
                
            case .upperRight:
                
                if rect.maxX - rect.minX == 0 || (x <= 0 && rect.maxX + x - spacing <= rect.minX) {
                    x = 1
                } else {
                    x = 1 + x / (rect.maxX - rect.minX)
                }
                if rect.maxY - rect.minY == 0 || (y >= 0 && rect.minY + y + spacing >= rect.maxY) {
                    y = 1
                } else {
                    y = 1 - y / (rect.maxY - rect.minY)
                }
                
                for i: Int in 0 ..< layer.points.count {
                    for j: Int in 0 ..< layer.points[i].count {
                        layer.points[i][j] = CGPoint(x: (layer.points[i][j].x - rect.minX) * x + rect.minX, y: rect.maxY - (rect.maxY - layer.points[i][j].y) * y)
                    }
                }
                
            case .bottomLeft:
                
                if rect.maxX - rect.minX == 0 || (x >= 0 && rect.minX + x + spacing >= rect.maxX) {
                    x = 1
                } else {
                    x = 1 - x / (rect.maxX - rect.minX)
                }
                if rect.maxY - rect.minY == 0 || (y <= 0 && rect.maxY + y - spacing <= rect.minY) {
                    y = 1
                } else {
                    y = 1 + y / (rect.maxY - rect.minY)
                }
                
                for i: Int in 0 ..< layer.points.count {
                    for j: Int in 0 ..< layer.points[i].count {
                        layer.points[i][j] = CGPoint(x: rect.maxX - (rect.maxX - layer.points[i][j].x) * x, y: (layer.points[i][j].y - rect.minY) * y + rect.minY)
                    }
                }
                
            case .bottomRight:
                
                if rect.maxX - rect.minX == 0 || (x <= 0 && rect.maxX + x - spacing <= rect.minX) {
                    x = 1
                } else {
                    x = 1 + x / (rect.maxX - rect.minX)
                }
                if rect.maxY - rect.minY == 0 || (y <= 0 && rect.maxY + y - spacing <= rect.minY) {
                    y = 1
                } else {
                    y = 1 + y / (rect.maxY - rect.minY)
                }
                
                for i: Int in 0 ..< layer.points.count {
                    for j: Int in 0 ..< layer.points[i].count {
                        layer.points[i][j] = CGPoint(x: (layer.points[i][j].x - rect.minX) * x + rect.minX, y: (layer.points[i][j].y - rect.minY) * y + rect.minY)
                    }
                }
                
            default:
                break
            }
            
            if layer.type == .rulerFreehand || layer.type == .areaFreehand {
                if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                    if layer.type == .rulerFreehand {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lengthPerPx)
                    } else {
                        layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lengthPerPx)
                    }
                } else {
                    layer.number = nil
                }
            }
            
            layer.draw()
            
        } else if layer.type == .text {
            let attributes = layer.text?.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: layer.text?.length ?? 0))
            
            let line = layer.text?.string.components(separatedBy: "\n") ?? []
            var charWidth: CGFloat = 0
            if let max = line.compactMap({ $0.count }).max() {
                charWidth = (layer.text?.size().width ?? 0.0) / CGFloat(max)
            } else {
                charWidth = (attributes?[NSAttributedString.Key.font] as? UIFont)?.pointSize ?? 0.0
            }
            
            switch point {
            case .centerLeft:
                if charWidth <= layer.points[0][1].x - (layer.points[0][0].x + delta.x) {
                    layer.points[0][0].x += delta.x
                } else {
                    return
                }
            case .centerRight:
                if charWidth <= (layer.points[0][1].x + delta.x) - layer.points[0][0].x {
                    layer.points[0][1].x += delta.x
                } else {
                    return
                }
            default:
                return
            }
            
            layer.draw()
            
        } else if layer.type == .rulerBase || layer.type == .rulerLine {
            
            switch point {
            case .bottomLeft,
                 .start,
                 .upperLeft:
                layer.points[0][0].x += delta.x
                layer.points[0][0].y += delta.y
                
            case .bottomRight,
                 .end,
                 .upperRight:
                layer.points[0][1].x += delta.x
                layer.points[0][1].y += delta.y
            default:
                break
            }
            
            if layer.type == .rulerBase {
                calcMeasuring()
            } else if layer.type == .rulerLine {
                if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                    layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lengthPerPx)
                } else {
                    layer.number = nil
                }
            }
            
            layer.draw()
            
        } else if layer.type == .rulerRect || layer.type == .areaRect {
            switch point {
            case .upperLeft:
                layer.points[0][0].x += delta.x
                layer.points[0][0].y += delta.y
                layer.points[0][1].y += delta.y
                layer.points[0][2].x += delta.x
                
            case .upperRight:
                layer.points[0][0].y += delta.y
                layer.points[0][1].x += delta.x
                layer.points[0][1].y += delta.y
                layer.points[0][3].x += delta.x
                
            case .bottomLeft:
                layer.points[0][0].x += delta.x
                layer.points[0][2].x += delta.x
                layer.points[0][2].y += delta.y
                layer.points[0][3].y += delta.y
                
            case .bottomRight:
                layer.points[0][1].x += delta.x
                layer.points[0][2].y += delta.y
                layer.points[0][3].x += delta.x
                layer.points[0][3].y += delta.y
                
            default:
                break
            }
            
            if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                if layer.type == .rulerRect {
                    layer.number = measuringUtil.length(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lengthPerPx
                    )
                } else {
                    layer.number = measuringUtil.area(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lengthPerPx
                    )
                }
            } else {
                layer.number = nil
            }
            
            layer.draw()
            
        } else if layer.type == .rulerPolygon || layer.type == .areaPolygon {
            switch point {
            case .general(let i):
                let old = layer.points[0][i]
                layer.points[0][i].x += delta.x
                layer.points[0][i].y += delta.y
                if layer.type == .areaPolygon {
                    if measuringUtil.hasIntersection(points: layer.points[0]) {
                        layer.points[0][i] = old
                    }
                }
            default:
                break
            }
            
            if let base = measuringBaseLayer, let lengthPerPx = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
                if layer.type == .rulerPolygon {
                    layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lengthPerPx)
                } else if layer.type == .areaPolygon {
                    layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lengthPerPx)
                }
            } else {
                layer.number = nil
            }
            
            layer.draw()
        }
        
        if let dic = layer.navigationPoint {
            for (key, val) in dic {
                navigationViews.filter({ $0.point?.toInt() == key }).first?.center = val
            }
        }
        
        if layer.type == .rulerBase || layer.type == .rulerLine || layer.type == .rulerRect || layer.type == .areaRect || layer.type == .rulerPolygon || layer.type == .areaPolygon {
            var p: CGPoint?
            switch point {
            case .start:
                p = layer.points[0][0]
            case .end:
                p = layer.points[0][1]
            case .upperLeft:
                p = layer.points[0][0]
            case .upperRight:
                p = layer.points[0][1]
            case .bottomLeft:
                p = layer.points[0][2]
            case .bottomRight:
                p = layer.points[0][3]
            case .general(let i):
                p = layer.points[0][i]
            default:
                break
            }
            if let p = p {
                delegate?.paintView(self, willMoveLoupe: layer, point: p)
            }
        }
        
        drawSelectNavigations(isRedraw: true)
    }
    
    func didDeMove(point: PaintSelectNavigationView.Point) {
        guard let layer = selectLayers?.first else {
            return
        }
        if layer.type == .text {
            var width = layer.points[0][1].x - layer.points[0][0].x
            var height = layer.points[0][1].y - layer.points[0][0].y
            
            let textSize = CGSize(width: layer.text?.size().width ?? 0.0, height: CGFloat.greatestFiniteMagnitude)
            
            if textSize.width < width {
                layer.points[0][1].x = layer.points[0][0].x + textSize.width
            }
            if textSize.height < height {
                layer.points[0][1].y = layer.points[0][0].y + textSize.height
            }
            width = layer.points[0][1].x - layer.points[0][0].x
            height = layer.points[0][1].y - layer.points[0][0].y
            
            if let dic = layer.navigationPoint {
                for (key, val) in dic {
                    navigationViews.filter({ $0.point?.toInt() == key }).first?.center = val
                }
            }
            
            drawSelectNavigations(isRedraw: true)
            
        } else if layer.type == .rulerBase || layer.type == .rulerLine || layer.type == .rulerRect || layer.type == .rulerPolygon || layer.type == .areaRect || layer.type == .areaPolygon {
            delegate?.paintView(self, didDeDisplayLoupe: layer)
        }
    }
}

extension PaintView {
   
    
    func save(layer_id: String, completion: (() -> Void)?) {
        
        
        let contentSize = bounds.size
        let contentsScale = self.contentsScale
        
        let layers = layer.sublayers?.compactMap({ $0 as? PaintLayer }) ?? []
        let shapes: [Shape] = []
        DispatchQueue.global(qos: .userInitiated).async(execute: { [weak self] in
            defer {
                DispatchQueue.main.sync(execute: { [weak self] in
                    self?.reinitializeUndo()
                    completion?()
                })
            }
            
            let dateUtil = DateUtil()
            let dateStr = dateUtil.getJSTDateString(.DateTime_Hyphen)
            
//            var plan_id = ""
//            
//            guard !plan_id.isEmpty else {
//                return
//            }
            
            for layer in layers {
                switch layer.type {
                case .oval:
//                    let a = [layer.points[0][0].x, layer.points[0][0].y]
//                    let b = [layer.points[0][3].x, layer.points[0][3].y]
//                    let shape = Shape(a: a, b: b, boundingRect: nil, fillColor: layer.fillColor, strokeColor: layer.strokeColor, strokeWidth: layer.lineWidth, fontName: nil, fontSize: nil, id: layer.identifier, text: nil, transform: nil, type: .ellipse)
                    print("")
                    
                case .freehand:
                    print(layer.points)
                    let points = layer.points
                    var segments: [Segment] = []
                    var pointBefore: [CGFloat]!
                    var startPoint: [CGFloat]!
                    for i in 0 ..< points.count {
                        for j in 0 ..< points[i].count - 1 {
                            let a: [CGFloat]!
                            if j != 0 {
                                a = pointBefore
                            } else {
                                let x: CGFloat = points[i][j].x
                                let y: CGFloat = points[i][j].y
                                a = [x,y]
                                startPoint = a
                            }

                            
                            let x1: CGFloat = points[i][j+1].x
                            let y1: CGFloat = points[i][j+1].y
                            let b = [x1, y1]
                            
                            pointBefore = b
                            let segment = Segment(a: a, b: b, width: 5)
                            segments.append(segment)

                        }
                    }
                    let encoder = JSONEncoder()
                    if let jsonData = try? encoder.encode(segments) {
                        if let jsonString = String(data: jsonData, encoding: . utf8) {
                        print(jsonString)
                        }
                    }
//                    print(segments)

                case .text:
                    print(layer.points)
                default:
                    break
                }
                print(layer.operation)
            }
            
            guard let deletes = self?.trashBox else {
                return
            }
            for (key, val) in deletes {
                
            }
        })
    }
    
    func drawSanaPaintLayer(id: String, type: String) -> PaintLayer? {
        let layer = PaintLayer()
        layer.identifier = id
        
        return nil
    }
   
    
    private func paintLayer(id: String, category: Int, type: Int, properties: String, geometry: String) -> PaintLayer? {
        let contentsSize = bounds.size
        
        let numberFormat = NumberFormatter()
        numberFormat.locale = Locale(identifier: "en_US_POSIX")
        let layer = PaintLayer()
        layer.identifier = id
        layer.strokeColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.clear.cgColor
        
        var strokeColor: UIColor = .clear
        var fillColor: UIColor = .clear
        var width: CGFloat = 1
        var fontSize: CGFloat = 1
        
        let properties = properties.components(separatedBy: ",")
        for property in properties {
//            if property.hasPrefix("sc=") {
//                let hex = property.replace(target: "sc=", withString: "")
//                strokeColor = UIColor(hexString: hex)
//
//            } else if property.hasPrefix("fc=") {
//                let hex = property.replace(target: "fc=", withString: "")
//                fillColor = UIColor(hexString: hex)
//
//            } else if property.hasPrefix("w=") {
//                guard let w = numberFormat.number(from: property.replace(target: "w=", withString: "")) else { continue }
//                width = CGFloat(truncating: w) / 1000 * contentsSize.height
//
//            } else if property.hasPrefix("lc=") {
//                let lc = property.replace(target: "lc=", withString: "")
//                if lc == "r" {
//                    layer.lineCap = CAShapeLayerLineCap.round
//                } else if lc == "b" {
//                    layer.lineCap = CAShapeLayerLineCap.butt
//                } else if lc == "s" {
//                    layer.lineCap = CAShapeLayerLineCap.square
//                } else {
//                    // default
//                    layer.lineCap = CAShapeLayerLineCap.round
//                }
//
//            } else if property.hasPrefix("o") {
//                guard let opacity = numberFormat.number(from: property.replace(target: "o=", withString: "")) else { continue }
//                layer.opacity = Float(truncating: opacity)
//
//            } else if property.hasPrefix("fs=") {
//                guard let fs = numberFormat.number(from: property.replace(target: "fs=", withString: "")) else { continue }
//                fontSize = CGFloat(truncating: fs) / 1000 * contentsSize.height
//            }
        }
        switch category {
        case 2:
            layer.strokeColor = strokeColor.cgColor
            layer.fillColor = fillColor.cgColor
            layer.baseLineWidth = width
            layer.lineWidth = layer.baseLineWidth
            
            switch type {
            case 1:
                layer.type = .pen
                layer.opacity = 1
                
            case 2:
                layer.type = .highlighter
                layer.opacity = 0.3
                
            default:
                return nil
            }
            
            for row in geometry.components(separatedBy: "\n") {
                for point in row.components(separatedBy: "|") {
                    let arr = point.components(separatedBy: ",")
                    guard arr.count == 2 else { continue }
                    guard let x = numberFormat.number(from: arr[0]), let y = numberFormat.number(from: arr[1]) else { continue }
                    
                    let p = CGPoint(x: CGFloat(truncating: x) / 1000 * contentsSize.width, y: CGFloat(truncating: y) / 1000 * contentsSize.height)
                    layer.points[layer.points.count - 1].append(p)
                }
                layer.points.append([])
            }
            
            for i in (0 ..< layer.points.count).reversed() {
                if layer.points[i].count <= 1 {
                    layer.points.remove(at: i)
                }
            }
        case 3:
            layer.strokeColor = strokeColor.cgColor
            layer.fillColor = fillColor.cgColor
            layer.baseLineWidth = width
            layer.lineWidth = layer.baseLineWidth
            
            switch type {
            case 2:
                layer.type = .arrow
            case 3:
                layer.type = .rect
                
                let p = geometry.components(separatedBy: ",")
                guard p.count == 4 else {
                    return nil
                }
                let xStr = p[0]
                let yStr = p[1]
                let widthStr = p[2]
                let heightStr = p[3]
                
                guard let x = numberFormat.number(from: xStr),
                      let y = numberFormat.number(from: yStr),
                      let width = numberFormat.number(from: widthStr),
                      let height = numberFormat.number(from: heightStr) else {
                    return nil
                }
                let point0 = CGPoint(
                    x: CGFloat(truncating: x) / 1000 * contentsSize.width,
                    y: CGFloat(truncating: y) / 1000 * contentsSize.height
                )
                let point1 = CGPoint(
                    x: (CGFloat(truncating: x) + CGFloat(truncating: width)) / 1000 * contentsSize.width,
                    y: CGFloat(truncating: y) / 1000 * contentsSize.height
                )
                let point2 = CGPoint(
                    x: CGFloat(truncating: x) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: y) + CGFloat(truncating: height)) / 1000 * contentsSize.height
                )
                let point3 = CGPoint(
                    x: (CGFloat(truncating: x) + CGFloat(truncating: width)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: y) + CGFloat(truncating: height)) / 1000 * contentsSize.height
                )
                
                layer.points[0].append(point0)
                layer.points[0].append(point1)
                layer.points[0].append(point2)
                layer.points[0].append(point3)
                
            case 4:
                layer.type = .oval
                
                let p = geometry.components(separatedBy: ",")
                guard p.count == 4 else {
                    return nil
                }
                let cxStr = p[0]
                let cyStr = p[1]
                let rxStr = p[2]
                let ryStr = p[3]
                
                guard let cx = numberFormat.number(from: cxStr),
                      let cy = numberFormat.number(from: cyStr),
                      let rx = numberFormat.number(from: rxStr),
                      let ry = numberFormat.number(from: ryStr) else {
                    return nil
                }
                let point0 = CGPoint(
                    x: (CGFloat(truncating: cx) - CGFloat(truncating: rx)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: cy) - CGFloat(truncating: ry)) / 1000 * contentsSize.height
                )
                let point1 = CGPoint(
                    x: (CGFloat(truncating: cx) + CGFloat(truncating: rx)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: cy) - CGFloat(truncating: ry)) / 1000 * contentsSize.height
                )
                let point2 = CGPoint(
                    x: (CGFloat(truncating: cx) - CGFloat(truncating: rx)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: cy) + CGFloat(truncating: ry)) / 1000 * contentsSize.height
                )
                let point3 = CGPoint(
                    x: (CGFloat(truncating: cx) + CGFloat(truncating: rx)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: cy) + CGFloat(truncating: ry)) / 1000 * contentsSize.height
                )
                
                layer.points[0].append(point0)
                layer.points[0].append(point1)
                layer.points[0].append(point2)
                layer.points[0].append(point3)

            case 5:
                layer.type = .line
                
            case 6:
                layer.type = .cross
                
                let row = geometry.components(separatedBy: "\n")
                guard row.count == 2 else {
                    return nil
                }
                let row0 = row[0].components(separatedBy: "|")
                let row1 = row[1].components(separatedBy: "|")
                
                guard row0.count == 2, row1.count == 2 else {
                    return nil
                }
                var points = [String]()
                points.append(row0[0])
                points.append(row1[1])
                points.append(row1[0])
                points.append(row0[1])
                
                var p: [CGPoint] = []
                for point in points {
                    let arr = point.components(separatedBy: ",")
                    guard arr.count == 2 else { continue }
                    
                    guard let x = numberFormat.number(from: arr[0]), let y = numberFormat.number(from: arr[1]) else { continue }
                    
                    p.append(CGPoint(x: CGFloat(truncating: x) / 1000 * contentsSize.width, y: CGFloat(truncating: y) / 1000 * contentsSize.height))
                }
                
                guard p.count == 4 else {
                    return nil
                }
                layer.points[0] = p
                
            default:
                return nil
            }
            
            switch type {
            case 2,
                 5:
                let p = geometry.components(separatedBy: "|")
                if p.count == 2 {
                    let p0 = p[0].components(separatedBy: ",")
                    let p1 = p[1].components(separatedBy: ",")
                    
                    if p0.count == 2, p1.count == 2 {
                        if let p0_x = numberFormat.number(from: p0[0]),
                           let p0_y = numberFormat.number(from: p0[1]),
                           let p1_x = numberFormat.number(from: p1[0]),
                           let p1_y = numberFormat.number(from: p1[1]) {
                            
                            let point0 = CGPoint(x: CGFloat(truncating: p0_x) / 1000 * contentsSize.width, y: CGFloat(truncating: p0_y) / 1000 * contentsSize.height)
                            let point1 = CGPoint(x: CGFloat(truncating: p1_x) / 1000 * contentsSize.width, y: CGFloat(truncating: p1_y) / 1000 * contentsSize.height)
                            layer.points[0].append(point0)
                            layer.points[0].append(point1)
                        }
                    }
                }
                
            case 3,
                 4,
                 6:
                layer.strokeColor = strokeColor.cgColor
                layer.fillColor = fillColor.cgColor
                layer.baseLineWidth = width
                layer.lineWidth = layer.baseLineWidth
                
            default:
                return nil
            }
            
        case 4:
            layer.strokeColor = UIColor.clear.cgColor
            layer.fillColor = strokeColor.cgColor
            layer.baseLineWidth = 1
            layer.lineWidth = 1
            
            switch type {
            case 1:
                layer.type = .text
                
                let arr = geometry.components(separatedBy: ",")
                guard arr.count >= 6 else {
                    return nil
                }
                guard let x = numberFormat.number(from: arr[0]),
                      let y = numberFormat.number(from: arr[1]),
                      let width = numberFormat.number(from: arr[2]),
                      let height = numberFormat.number(from: arr[3]) else {
                    return nil
                }
                layer.points[0].append(
                    CGPoint(
                        x: CGFloat(truncating: x) / 1000 * contentsSize.width,
                        y: CGFloat(truncating: y) / 1000 * contentsSize.height
                    )
                )
                layer.points[0].append(
                    CGPoint(
                        x: (CGFloat(truncating: x) + CGFloat(truncating: width)) / 1000 * contentsSize.width,
                        y: (CGFloat(truncating: y) + CGFloat(truncating: height)) / 1000 * contentsSize.height
                    )
                )
                
                var text = ""
                for i in 6 ..< arr.count {
                    if i == 6 {
                        text = arr[i]
                    } else {
                        text += ",\(arr[i])"
                    }
                }
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                style.lineBreakMode = .byCharWrapping
                
                if fontSize <= 0 {
                    fontSize = 1
                }
                let dict: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.paragraphStyle: style,
                    NSAttributedString.Key.kern: 0.0,
                    NSAttributedString.Key.font: UIFont(name: "IPAexGothic", size: fontSize)!,
                    NSAttributedString.Key.foregroundColor: strokeColor
                ]
                
                layer.text = NSAttributedString(string: text, attributes: dict)
                
            default:
                return nil
            }
            
        case 5:
            layer.strokeColor = strokeColor.cgColor
            layer.baseLineWidth = width
            layer.lineWidth = layer.baseLineWidth
            
            switch type {
            case 2:
                layer.type = .rulerLine
            case 3:
                layer.type = .rulerRect
            case 6:
                layer.type = .areaRect
            case 10:
                layer.type = .rulerPolygon
            case 7:
                layer.type = .areaPolygon
            case 5:
                layer.type = .rulerFreehand
            case 9:
                layer.type = .areaFreehand
            default:
                return nil
            }
            
            switch type {
            case 2:
                let p = geometry.components(separatedBy: "|")
                guard p.count == 2 else {
                    return nil
                }
                let p0 = p[0].components(separatedBy: ",")
                let p1 = p[1].components(separatedBy: ",")
                
                guard p0.count == 2, p1.count == 2 else {
                    return nil
                }
                guard let p0_x = numberFormat.number(from: p0[0]),
                      let p0_y = numberFormat.number(from: p0[1]),
                      let p1_x = numberFormat.number(from: p1[0]),
                      let p1_y = numberFormat.number(from: p1[1]) else {
                    return nil
                }
                let point0 = CGPoint(x: CGFloat(truncating: p0_x) / 1000 * contentsSize.width, y: CGFloat(truncating: p0_y) / 1000 * contentsSize.height)
                let point1 = CGPoint(x: CGFloat(truncating: p1_x) / 1000 * contentsSize.width, y: CGFloat(truncating: p1_y) / 1000 * contentsSize.height)
                layer.points[0].append(point0)
                layer.points[0].append(point1)
                
            case 3,
                 6:
                let p = geometry.components(separatedBy: ",")
                guard p.count == 4 else {
                    return nil
                }
                let xStr = p[0]
                let yStr = p[1]
                let widthStr = p[2]
                let heightStr = p[3]
                
                guard let x = numberFormat.number(from: xStr),
                      let y = numberFormat.number(from: yStr),
                      let width = numberFormat.number(from: widthStr),
                      let height = numberFormat.number(from: heightStr) else {
                    return nil
                }
                let point0 = CGPoint(
                    x: CGFloat(truncating: x) / 1000 * contentsSize.width,
                    y: CGFloat(truncating: y) / 1000 * contentsSize.height
                )
                let point1 = CGPoint(
                    x: (CGFloat(truncating: x) + CGFloat(truncating: width)) / 1000 * contentsSize.width,
                    y: CGFloat(truncating: y) / 1000 * contentsSize.height
                )
                let point2 = CGPoint(
                    x: CGFloat(truncating: x) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: y) + CGFloat(truncating: height)) / 1000 * contentsSize.height
                )
                let point3 = CGPoint(
                    x: (CGFloat(truncating: x) + CGFloat(truncating: width)) / 1000 * contentsSize.width,
                    y: (CGFloat(truncating: y) + CGFloat(truncating: height)) / 1000 * contentsSize.height
                )
                
                layer.points[0].append(point0)
                layer.points[0].append(point1)
                layer.points[0].append(point2)
                layer.points[0].append(point3)
                
            case 5,
                 7,
                 9,
                 10:
                for point in geometry.components(separatedBy: "|") {
                    let arr = point.components(separatedBy: ",")
                    guard arr.count == 2 else { continue }
                    guard let x = numberFormat.number(from: arr[0]), let y = numberFormat.number(from: arr[1]) else { continue }
                    
                    let p = CGPoint(x: CGFloat(truncating: x) / 1000 * contentsSize.width, y: CGFloat(truncating: y) / 1000 * contentsSize.height)
                    layer.points[layer.points.count - 1].append(p)
                }
                if type == 10 || type == 5 {
                    guard layer.points[0].count > 1 else {
                        return nil
                    }
                } else {
                    guard layer.points[0].count > 2 else {
                        return nil
                    }
                }
                
            default:
                return nil
            }
            
        default:
            return nil
        }
        
        return layer
    }
}

// private
extension PaintView {
    private func location(touches: Set<UITouch>, with event: UIEvent?) -> CGPoint? {
        guard let count = event?.allTouches?.count, count == 1 else {
            return nil
        }
        guard let touch = touches.first else {
            return nil
        }
        var point = touch.location(in: self)
        
        // 補正
        if point.x < 0 {
            point.x = 0
        }
        if frame.size.width < point.x {
            point.x = frame.size.width
        }
        if point.y < 0 {
            point.y = 0
        }
        if frame.size.height < point.y {
            point.y = frame.size.height
        }
        
        return point
    }
    
    private func selectLayer(point: CGPoint) {
        guard let layerCount = layer.sublayers?.count else {
            return
        }
        
        for i in (0 ..< layerCount).reversed() {
            guard let layer = layer.sublayers?[i] as? PaintLayer else { continue }
            if isOld {
                if layer.isTouch(point) {
                    layer.name = selecting
                    return
                }
            } else {
                if layer.isTouch(point, zoomScale: zoomScale) {
                    layer.name = selecting
                    return
                }
            }
        }
        
        for i in 0 ..< layerCount {
            layer.sublayers?[i].name = nil
        }
    }
    
    private func isTouchLayers(point: CGPoint) -> [PaintLayer]? {
        let zoomScale = self.zoomScale
        let name = navigation
        if let subLayers = layer.sublayers?.compactMap({ l -> PaintLayer? in
            if let layer = l as? PaintLayer, layer.name != name {
                return layer
            } else {
                return nil
            }
        }) {
            return subLayers.filter { $0.isTouch(point, zoomScale: zoomScale) }
        }
        return nil
    }
    
    private func drawSelectNavigations(isRedraw: Bool = false) {
        removeSelectNavigationLayers()
        if !isRedraw {
            removeSelectNavigationViews()
        }
        defer {
            if isRedraw {
                for view in navigationViews {
                    bringSubviewToFront(view)
                }
            }
        }
        
        guard let layers = selectLayers else {
            return
        }
        for layer in layers {
            if let navi = layer.navigationLayer() {
                navi.name = navigation
                navi.lineWidth = 1 / zoomScale
                
                self.layer.addSublayer(navi)
            }
        }
        
        guard let navigationPoint = layers.first?.navigationPoint, !isRedraw else {
            return
        }
        let rect: CGRect = CGRect(x: 0, y: 0, width: 36 / zoomScale, height: 36 / zoomScale)
        
        for (key, val) in navigationPoint {
            let view = PaintSelectNavigationView(frame: rect)
            view.zoomScale = zoomScale
            view.center = val
            view.point = PaintSelectNavigationView.Point(rawValue: key)
            view.delegate = self

            addSubview(view)
        }
    }
    
    private func move(point: CGPoint) {
        defer {
            lastTouchPoint = point
        }
        guard let last = lastTouchPoint, let layers = selectLayers else {
            return
        }
        
        let delta = CGPoint(x: point.x - last.x, y: point.y - last.y)
        
        let undo = PaintUndoObject()
        undo.operation = "U"
        undo.paintObjects = []
        
        for layer in layers {
            let oldLayer = layer.copyLayer()
            oldLayer.operation = .edit
            if let oldPoint = firstTouchPoint {
                oldLayer.points = oldPoint
            }
            undo.paintObjects.append(oldLayer.paintObject())
            if layer.operation != .new {
                layer.operation = .edit
            }
            
            for i in 0 ..< layer.points.count {
                for j in 0 ..< layer.points[i].count {
                    layer.points[i][j].x += delta.x
                    layer.points[i][j].y += delta.y
                }
            }
            
            layer.draw()
        }
        
        if !undo.paintObjects.isEmpty, !isFirstMoved {
            undoStack.insert(undo, at: 0)
            redoStack = []
            isFirstMoved = true
        }
    }
    
    private func removeSelectNavigations() {
        removeSelectNavigationLayers()
        removeSelectNavigationViews()
    }
    
    private func removeSelectNavigationLayers() {
        guard let layers = navigationLayers else {
            return
        }
        for layer in layers {
            layer.removeFromSuperlayer()
        }
    }
    
    private func removeSelectNavigationViews() {
        for view in navigationViews {
            view.removeFromSuperview()
        }
    }
    
    private func calcMeasuring() {
        guard let layers = measuringLayers else {
            return
        }
        var lengthPerPx: Double?
        if let base = measuringBaseLayer, let lpp = measuringUtil.lengthPerPx(points: base.points[0], length: base.number) {
            lengthPerPx = lpp
        }
        for layer in layers {
            if let lpp = lengthPerPx {
                if layer.type == .rulerLine {
                    layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                } else if layer.type == .rulerRect {
                    layer.number = measuringUtil.length(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lpp
                    )
                } else if layer.type == .areaRect {
                    layer.number = measuringUtil.area(
                        rect: CGRect(
                            x: layer.points[0][0].x,
                            y: layer.points[0][0].y,
                            width: CGFloat(fabsf(Float(layer.points[0][0].x - layer.points[0][3].x))),
                            height: CGFloat(fabsf(Float(layer.points[0][0].y - layer.points[0][3].y)))
                        ),
                        lengthPerPx: lpp
                    )
                } else if layer.type == .rulerPolygon {
                    if layer.name == drawing {
                        layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                    } else {
                        layer.number = measuringUtil.length(points: layer.points[0], isClose: true, lengthPerPx: lpp)
                    }
                } else if layer.type == .rulerFreehand {
                    layer.number = measuringUtil.length(points: layer.points[0], lengthPerPx: lpp)
                } else if layer.type == .areaPolygon || layer.type == .areaFreehand {
                    layer.number = measuringUtil.area(points: layer.points[0], lengthPerPx: lpp)
                }
            } else {
                layer.number = nil
            }
            layer.draw()
        }
    }
}

final class MeasuringUtil: NSObject {
    private func distance(points: [CGPoint], isClose: Bool = false) -> Double? {
        guard points.count > 1 else {
            return nil
        }
        var distance: Double = 0
        for i in 1 ..< points.count {
            let d = sqrt(pow(Double(points[i - 1].x - points[i].x), 2) + pow(Double(points[i - 1].y - points[i].y), 2))
            distance += d
        }
        if points.count > 2, isClose {
            // 始点終点を結ぶ
            let d = sqrt(pow(Double(points[0].x - points[points.count - 1].x), 2) + pow(Double(points[0].y - points[points.count - 1].y), 2))
            distance += d
        }
        return distance
    }
    
    private func distanceOfBezier(start: CGPoint, end: CGPoint, control: CGPoint) -> Double {
        //https://qiita.com/codelynx/items/fec92e40b4d5b145b9e6
        let a = CGPoint(x: start.x - 2 * control.x + end.x, y: start.y - 2 * control.y * end.y)
        let b = CGPoint(x: 2 * control.x - 2 * start.x, y: 2 * control.y - 2 * start.y)
        let A = Double(4 * (a.x * a.x + a.y * a.y))
        let B = Double(4 * (a.x * b.x + a.y * b.y))
        let C = Double(b.x * b.x + b.y * b.y)
        let Sabc = 2 * sqrt(A + B + C)
        let A_2 = sqrt(A)
        let A_32 = 2 * A * A_2
        let C_2 = 2 * sqrt(C)
        let BA = B / A_2
        let L = (A_32 * Sabc + A_2 * B * (Sabc - C_2) + (4 * C * A - B * B) * log((2 * A_2 + BA + Sabc) / (BA + C_2))) / (4 * A_32)
        return L
    }
    
    func lengthPerPx(points: [CGPoint], length: Double!) -> Double? {
        guard let l = length else {
            return nil
        }
        guard let distance = distance(points: points) else {
            return nil
        }
        return l / distance
    }
    
    func length(points: [CGPoint], isClose: Bool = false, lengthPerPx: Double) -> Double? {
        guard let distance = distance(points: points, isClose: isClose) else {
            return nil
        }
        return floor(distance * lengthPerPx * 10) / 10
    }
    
    func length(rect: CGRect, lengthPerPx: Double) -> Double {
        let width = Double(rect.size.width) * lengthPerPx
        let height = Double(rect.size.height) * lengthPerPx
        let d = (width + height) * 2
        return floor(d * 10) / 10
    }
    
    private func lengthOfFreehand(points: [CGPoint], lengthPerPx: Double) -> Double? {
        if points.count == 2 {
            return length(points: points, lengthPerPx: lengthPerPx)
        } else if points.count > 2 {
            var length: Double = 0
            
            let f = CGPoint(x: (points[0].x + points[1].x) / 2, y: (points[0].y + points[1].y) / 2)
            
            length = self.length(points: [points[0], f], lengthPerPx: lengthPerPx)!
            
            for i in 2 ..< points.count {
                let mid = CGPoint(x: (points[i - 1].x + points[i].x) / 2, y: (points[i - 1].y + points[i].y) / 2)
                let b_mid = CGPoint(x: (points[i - 2].x + points[i - 1].x) / 2, y: (points[i - 2].y + points[i - 1].y) / 2)
                length += distanceOfBezier(start: b_mid, end: mid, control: points[i - 1])
            }
            
            let l = CGPoint(x: (points[points.count - 2].x + points[points.count - 1].x) / 2, y: (points[points.count - 2].y + points[points.count - 1].y) / 2)
            length += self.length(points: [l, points[points.count - 1]], lengthPerPx: lengthPerPx)!
            
            return length
        } else {
            return nil
        }
    }
    
    func area(rect: CGRect, lengthPerPx: Double) -> Double {
        let width = Double(rect.size.width) * lengthPerPx
        let height = Double(rect.size.height) * lengthPerPx
        let area = width * height / 1000000 // ㎟ > ㎡
        return floor(area * 10) / 10
    }
    
    func area(points: [CGPoint], lengthPerPx: Double) -> Double? {
        guard points.count > 2 else {
            return nil
        }
        
        var area: Double = 0
        for i in 0 ..< points.count {
            let a = i == 0 ? points.count - 1 : i - 1
            let b = i == points.count - 1 ? 0 : i + 1
            
            area += Double((points[a].x - points[b].x) * points[i].y)
        }
        
        area = fabs(area) / 2
        area *= pow(lengthPerPx, 2)
        area /= 1000000 // ㎟ > ㎡
        
        return floor(area * 10) / 10
    }
    
    private func hasIntersection(line1 start: CGPoint, end: CGPoint, points: [CGPoint]) -> Bool {
        for i in (1 ..< points.count - 1).reversed() {
            if intersection(line1: start, end1: end, line2: points[i], end2: points[i - 1]) != nil {
                return true
            }
        }
        return false
    }
    
    func hasIntersection(points: [CGPoint]) -> Bool {
        guard points.count > 3 else {
            return false
        }
        for i in 0 ..< points.count - 3 {
            for j in i + 2 ..< points.count - 1 {
                if intersection(line1: points[i], end1: points[i + 1], line2: points[j], end2: points[j + 1]) != nil {
                    return true
                }
            }
        }
        // 始点-終点ラインの交差判定
        for i in 1 ..< points.count - 2 {
            if intersection(line1: points[0], end1: points[points.count - 1], line2: points[i], end2: points[i + 1]) != nil {
                return true
            }
        }
        return false
    }
    
    private func intersection(line1 start1: CGPoint, end1: CGPoint, line2 start2: CGPoint, end2: CGPoint) -> CGPoint? {
        let d = (end1.x - start1.x) * (end2.y - start2.y) - (end1.y - start1.y) * (end2.x - start2.x)
        guard d != 0 else {
            return nil
        }
        let u = ((start2.x - start1.x) * (end2.y - start2.y) - (start2.y - start1.y) * (end2.x - start2.x)) / d
        let v = ((start2.x - start1.x) * (end1.y - start1.y) - (start2.y - start1.y) * (end1.x - start1.x)) / d
        guard u >= 0, u <= 1 else {
            return nil
        }
        guard v >= 0, v <= 1 else {
            return nil
        }
        return CGPoint(x: start1.x + u * (end1.x - start1.x), y: start1.y + u * (end1.y - start1.y))
    }
}
