//
//  UIImageView+extension.swift
//  arrangement
//
//  Created by Phạm Công on 20/01/2022.
//  Copyright © 2022 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation
import UIKit
extension UIImageView{
    func addBorder(color: UIColor){
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = color.cgColor
    }
    
    func setRatioImage(ratio: Double){
        self.translatesAutoresizingMaskIntoConstraints = false
        for item in self.constraints {
            if item.firstAttribute == .width || item.firstAttribute == .height {
                self.removeConstraint(item)
            }
        }
        self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: CGFloat(ratio)).isActive = true
    }
}
