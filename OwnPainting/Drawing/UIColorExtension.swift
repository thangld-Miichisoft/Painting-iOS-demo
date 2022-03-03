//
//  UIColorExtension.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hexString: String) {
        var hexString = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        var color: UInt32 = 0
        
        if hexString.hasPrefix("#") {
            hexString = String(hexString[hexString.index(hexString.startIndex, offsetBy: 1)...])
        }
        if let i = UInt32(hexString, radix: 16) {
            color = i
        }
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    convenience init(hexString1:String) {
      var hexString = hexString1.trimmingCharacters(in: .whitespacesAndNewlines)

      if hexString.hasPrefix("#") {
          hexString = String(hexString.dropFirst())
      }

      if hexString.lowercased().hasPrefix("0x") {
          hexString = String(hexString.dropFirst(2))
      }

      while hexString.count < 8 {
          hexString.append("F")
      }

      let scanner = Scanner(string: hexString)

      var color: UInt64 = 0

      scanner.scanHexInt64(&color)

      let mask = 0x000000FF
      let r = Int(color >> 24) & mask
      let g = Int(color >> 16) & mask
      let b = Int(color >> 8) & mask
      let a = Int(color) & mask

      let red   = CGFloat(r) / 255.0
      let green = CGFloat(g) / 255.0
      let blue  = CGFloat(b) / 255.0
      let alpha = CGFloat(a) / 255.0

      self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    
    var hexString: String {
      var r: CGFloat = 0
      var g: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      getRed(&r, green: &g, blue: &b, alpha: &a)

      let rgb:Int = (Int)(r*255)<<24 | (Int)(g*255)<<16 | (Int)(b*255)<<8 | (Int)(a*255)

      return NSString(format:"#%08x", rgb) as String
    }
    
    class func destructive() -> UIColor {
        return UIColor(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1)
    }
    
    class func disabledColor() -> UIColor {
        return UIColor(white: 0.75, alpha: 1)
    }
    
    class func tintColor() -> UIColor {
        return UIButton(type: .system).tintColor
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }

    /// Make an image from current color with specific size
    /// - Parameter size: CGSize
    /// - Returns: UIImage?
    func toImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
