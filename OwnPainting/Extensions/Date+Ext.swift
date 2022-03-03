//
//  Date+Ext.swift
//  arrangement
//
//  Created by Duc Do on 11/11/19.
//  Copyright © 2019 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation

extension Date {
    static func getListDate(from: Date, to: Date) -> [Date] {
        if from == to {
            return [from]
        } else {
            var array = [Date]()
            var start = from < to ? from : to
            let end = from < to ? to : from
            while start <= end {
                array.append(start)
                start = start.adding(.day, value: 1)
            }
            return array
        }
    }
}
