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
    
    init(category: Int, conf: Float, XMin: Double, YMin: Double, XMax: Double, YMax: Double, imageSize: CGSize){
        // XMin, YMin, XMax, YMax represent normalized co-ordinates.
        // To return co-ordinates with reference to the current image, take the product of
        // XMax or XMin and Double(imageSize.width), YMax or YMin and Double(imageSize.height)

        self.label = category
        self.confidence = conf
        self.rect = CGRect(x: XMin, y: YMin, width: XMax - XMin, height: YMax - YMin)
    }
    
     func toDict() -> [String:Any]{
        let objectDict = ["XMin": self.rect.minX, "YMin": self.rect.minY, "Height": self.rect.height, "Width":self.rect.width, "Label": self.label, "Confidence": self.confidence] as [String : Any]
        
        
        return objectDict
    }
}
