//
//  DrawingViewModel.swift
//  arrangement
//
//  Created by Phạm Công on 14/01/2022.
//  Copyright © 2022 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation
import RxSwift

class BaseDrawingViewModel{
    var drawing: Drawing?
    var signatureRatio: Double! = 1.0
    var titleDrawing: String!
    var delta: CGSize! = CGSize(width: 1, height: 1)
    var size: CGSize!
}
