//
//  Collection+Extension.swift
//  arrangement
//
//  Created by Duc Do on 9/26/18.
//  Copyright © 2018 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
