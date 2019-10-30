//
//  PriorsGen.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation

@available(iOS 11.2, *)
struct PriorsGen{
    static let featureMapSizeBig = 19
    static let featureMapSizeSmall = 10
    static let shrinkageBig = 32
    static let shrinkageSmall = 16
    static let aspectRatioOne = 2
    static let aspectRationTwo = 3
    static let noOfPriorsPerLocation = 6
    static let boxSizeSmallLayerOne = 60
    static let boxSizeBigLayerOne = 105
    static let boxSizeBigLayerTwo = 150
    
    @available(iOS 11.2, *)
    static func genPriors(featureMapSize: Int, shrinkage: Int, boxSizeMin: Int, boxSizeMax: Int, aspectRatioOne : Int, aspectRatioTwo: Int, noOfPriors: Int) -> [CGRect]{
        
        let image_size = SsdDetect.SSDCardWidth
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
        
        let priorsOne = PriorsGen.genPriors(featureMapSize: PriorsGen.featureMapSizeBig, shrinkage: PriorsGen.shrinkageSmall, boxSizeMin: PriorsGen.boxSizeSmallLayerOne, boxSizeMax: PriorsGen.boxSizeBigLayerOne, aspectRatioOne: PriorsGen.aspectRatioOne, aspectRatioTwo: PriorsGen.aspectRationTwo, noOfPriors: PriorsGen.noOfPriorsPerLocation)
        let priorsTwo = PriorsGen.genPriors(featureMapSize: PriorsGen.featureMapSizeSmall, shrinkage: PriorsGen.shrinkageBig, boxSizeMin: PriorsGen.boxSizeBigLayerOne, boxSizeMax: PriorsGen.boxSizeBigLayerTwo, aspectRatioOne: PriorsGen.aspectRatioOne, aspectRatioTwo: PriorsGen.aspectRationTwo, noOfPriors: PriorsGen.noOfPriorsPerLocation)
        let priorsCombined = priorsOne + priorsTwo
        
        return priorsCombined
        
        
    }
}

extension Float {
    func clamp(minimum: Float =  0.0, maximum: Float =  1.0) -> Float {
        return max(minimum, min(maximum, self))
    }
    
}
