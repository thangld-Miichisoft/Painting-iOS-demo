//
//  StringExtension.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import Foundation

extension String {
    func replace(target: String, withString: String) -> String {
        return replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

