//
//  DetectedSSDBox.swift
//  CardScan
//
//  Created by Zain on 8/7/19.
//

import Foundation

struct DetectedSSDBox {
    let rect: CGRect
    let label: Int
    let confidence: Float
    let imgSize: CGSize
    
    init(category: Int, conf: Float, XMin: Double, YMin: Double, XMax: Double, YMax: Double, imageSize: CGSize){

        let XMin_ = XMin * Double(imageSize.width)
        let XMax_ = XMax * Double(imageSize.width)
        let YMin_ = YMin * Double(imageSize.height)
        let YMax_ = YMax * Double(imageSize.height)

        self.label = category
        self.confidence = conf
        self.rect = CGRect(x: XMin_, y: YMin_, width: XMax_ - XMin_, height: YMax_ - YMin_)
        self.imgSize = imageSize
    }
    
     func toDict() -> [String:Any]{
        let objectDict = ["XMin": self.rect.minX/self.imgSize.width, "YMin": self.rect.minY/self.imgSize.height, "Height": self.rect.height/self.imgSize.height,
                          "Width":self.rect.width/self.imgSize.width, "Label": self.label, "Confidence": self.confidence] as [String : Any]
        
        
        return objectDict
    }
}
