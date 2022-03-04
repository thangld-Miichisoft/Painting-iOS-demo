//
//  DrawingViewModel.swift
//  arrangement
//
//  Created by Phạm Công on 13/02/2022.
//  Copyright © 2022 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class DrawingViewModel: BaseDrawingViewModel {
    
    var isScrollMode : Bool = true
    var isScrollingEvent = PublishSubject<Bool>()
    
    var background_image: Variable<UIImage?> = Variable(nil)
}
