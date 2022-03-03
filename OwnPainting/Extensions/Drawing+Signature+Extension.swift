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
    
    func translation(with point: CGPoint)->CGPoint{
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
    
    func getDelta(with otherPoint: CGPoint)->CGPoint {
        return CGPoint(x: self.x - otherPoint.x, y: self.y - otherPoint.y)
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



extension CGRect {
    func withScale(with scaleSize: CGSize)->CGRect{
        return CGRect(origin: self.origin.withScale(with: scaleSize), size: self.size.withScale(with: scaleSize))
    }
}

