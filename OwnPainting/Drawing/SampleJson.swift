//
//  SampleJson.swift
//  arrangement
//
//  Created by Phạm Công on 10/02/2022.
//  Copyright © 2022 YSL Solution Co.,Ltd. All rights reserved.
//

import Foundation

// just use for debuging, will delete when API was provided
class SampleJson{
   static func readJsonDrawing(complettion: @escaping (Drawing?) -> Void){
        if let path = Bundle.main.path(forResource: "jsonSample", ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonDecoder = JSONDecoder()
                let drawingData = try? jsonDecoder.decode(Drawing.self, from: data)
                complettion(drawingData)
                
              } catch {
                   complettion(nil)
              }
        }
    }
}
