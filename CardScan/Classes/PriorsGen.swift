//
//  PriorsGen.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation

struct PriorsGen{
    
    static func genPriors(featureMapSize: Int, shrinkage: Int, boxSizeMin: Int, boxSizeMax: Int, aspectRatioOne : Int, aspectRatioTwo: Int, noOfPriors: Int) -> [CGRect]{
        
        let image_size = 300
        let scale = Float(image_size) / Float(shrinkage);
        var boxes = [CGRect]()
        var x_center: Float; var y_center: Float
        var size: Float
        var ratioOne: Float; var ratioTwo : Float
        var h: Float; var w: Float;
        
        for j in 0..<featureMapSize{
            for i in 0..<featureMapSize{
                x_center = ((Float(i) + 0.5) / scale).clamp()
                y_center = ((Float(j) + 0.5) / scale).clamp()
                
                
                size = Float(boxSizeMin)
                h = (size / Float(image_size)).clamp()
                w = (size / Float(image_size)).clamp()
                
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center), width: CGFloat(w), height: CGFloat(h)))
                
                size = sqrt(Float(boxSizeMax) * Float(boxSizeMin))
                h = (size / Float(image_size)).clamp()
                w = (size / Float(image_size)).clamp()
                
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center), width: CGFloat(w), height: CGFloat(h)))
                
                size = Float(boxSizeMin)
                h = (size / Float(image_size)).clamp()
                w = (size / Float(image_size)).clamp()
                
                ratioOne = sqrt(Float(aspectRatioOne))
                ratioTwo = sqrt(Float(aspectRatioTwo))
                
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center),
                                    width: CGFloat((w / ratioOne).clamp()), height: CGFloat((h * ratioOne).clamp())))
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center),
                                    width: CGFloat((w * ratioOne).clamp()), height: CGFloat((h / ratioOne).clamp())))
                
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center),
                                    width: CGFloat((w / ratioTwo).clamp()), height: CGFloat((h * ratioTwo).clamp())))
                
                
                boxes.append(CGRect(x: CGFloat(x_center), y: CGFloat(y_center),
                                    width: CGFloat(( w * ratioTwo).clamp()), height: CGFloat((h / ratioTwo).clamp())))
            }
        }
        return boxes
    }
    
    static func combinePriors() -> [CGRect]{
        
        let priorsOne = PriorsGen.genPriors(featureMapSize: 19, shrinkage: 16, boxSizeMin: 60, boxSizeMax: 105, aspectRatioOne: 2, aspectRatioTwo: 3, noOfPriors: 6)
        let priorsTwo = PriorsGen.genPriors(featureMapSize: 10, shrinkage: 32, boxSizeMin: 105, boxSizeMax: 150, aspectRatioOne: 2, aspectRatioTwo: 3, noOfPriors: 6)
        let priorsCombined = priorsOne + priorsTwo
        
        return priorsCombined
        
        
    }
}

extension Float {
    func clamp(minimum: Float =  0.0, maximum: Float =  1.0) -> Float {
        return max(minimum, min(maximum, self))
    }
    
}
