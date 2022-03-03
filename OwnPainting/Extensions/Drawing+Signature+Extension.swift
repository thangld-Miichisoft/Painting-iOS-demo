//
//  Drawing+Signature+Extension.swift
//  arrangement
//
//  Created by Phạm Công on 25/02/2022.
//  Copyright © 2022 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension CGPoint {
    func withScale(with scaleSize: CGSize)->CGPoint{
        return CGPoint(x: self.x*scaleSize.width, y: self.y*scaleSize.height)
    }
}
extension CGSize {
    func toRevert()->CGSize{
        return CGSize(width: 1/self.width, height: 1/self.height)
    }
    
    func withScale(with scaleSize: CGSize)->CGSize{
        return CGSize(width: self.width*scaleSize.width, height: self.height*scaleSize.height)
    }
}

extension Shape {
    func resizeShape(with scaleSize: CGSize)-> Shape{
        if let pen = self as? PenShape {
            let segments = pen.segments.map({PenLineSegment(a: $0.a.withScale(with: scaleSize), b: $0.b.withScale(with: scaleSize), width: $0.width)})
            pen.segments = segments
            pen.start = pen.start.withScale(with: scaleSize)
            pen.strokeColor = .red
            return pen
        }
        else if let text = self as? TextShape {
            let tranform = text.transform
            text.transform = ShapeTransform(translation: tranform.translation.withScale(with: scaleSize), rotation: tranform.rotation, scale: tranform.scale)
            text.boundingRect = text.boundingRect.withScale(with: scaleSize)
            text.fillColor = .red
            return text
        }else if let ellipseShape = self as? EllipseShape {
            let tranform = ellipseShape.transform
            ellipseShape.transform = ShapeTransform(translation: tranform.translation.withScale(with: scaleSize), rotation: tranform.rotation, scale: tranform.scale)
            ellipseShape.a = ellipseShape.a.withScale(with: scaleSize)
            ellipseShape.b = ellipseShape.b.withScale(with: scaleSize)
            ellipseShape.strokeColor = .red
            
           return ellipseShape
        }
        return self
    }
    func toJson()->[String: Any]{
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted]
        let jsonData = try! jsonEncoder.encode(self)
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                return json
            }
        }catch {
            return [:]
        }
        return [:]
    }
}

extension Drawing {
    func toResize(with delta: CGSize)->Drawing{
        let drawing = Drawing(size: self.size.withScale(with: delta))
        let newShapes = self.shapes.map({$0.resizeShape(with: delta)})
        newShapes.map({drawing.add(shape: $0)})
        print(drawing.toString())
        return drawing
    }
    
    func toImage(baseImage: UIImage?)->UIImage?{
        if let baseImage = baseImage {
            return self.render(over: baseImage)
        }else{
            return self.render()
        }
    }
    func toImageDrawing(baseImage: UIImage)->UIImage?{
        return self.render(over: baseImage, scale: 1.0)
    }

    
    func toJson()->[String: Any]{
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted]
        let jsonData = try! jsonEncoder.encode(self)
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                return json
            }
        }catch {
            return [:]
        }
        return [:]
    }
    func toString()->String{
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted]
        let jsonData = try! jsonEncoder.encode(self)
        return String(data: jsonData, encoding: .utf8)!
        
    }
    
    func copy()->Drawing{
        let size = self.size
        let shapes = self.shapes
        self.shapes.map({self.remove(shape: $0)})
        
        let drawing = Drawing.init(size: size)
        shapes.map({drawing.add(shape: $0)})
        return drawing
    }
    
}

extension CGRect {
    func withScale(with scaleSize: CGSize)->CGRect{
        return CGRect(origin: self.origin.withScale(with: scaleSize), size: self.size.withScale(with: scaleSize))
    }
}

extension Drawing {
    public func render(over image: UIImage?, scale:CGFloat = 0.0) -> UIImage? {
        let size = image?.size ?? self.size
        let shapesImage = render(size: size, scale: scale)
        return DrawsanaUtilities.renderImage(size: size, scale: scale) { (context: CGContext) -> Void in
            image?.draw(at: .zero)
            shapesImage?.draw(at: .zero)
        }
    }
    public func render(size: CGSize? = nil, scale:CGFloat = 0.0) -> UIImage? {
        let size = size ?? self.size
        return DrawsanaUtilities.renderImage(size: size, scale:scale) { (context: CGContext) -> Void in
            context.saveGState()
            context.scaleBy(
                x: size.width / self.size.width,
                y: size.height / self.size.height)
            for shape in self.shapes {
                shape.render(in: context)
            }
            context.restoreGState()
        }
    }
}
