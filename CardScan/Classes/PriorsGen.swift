//
//  PriorsGen.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation

@available(iOS 11.2, *)
struct PriorsGen{
    /**
            This struct represents the logic to generate initiail bounding boxes or priors for our implementation of SSD.
            We use outputs from two layers of MobileNet V2. In the existing implementation the input size = 300, and
            repective feature map sizes are 19 x 19 at output layer 1 and 10 x 10 at output layer 2.
     */
    
    // At output layer 1 the feature map size = 19 x 19
    static let featureMapSizeBig = 19
    
    // At output layer 2, the feature map size = 10 x 10
    static let featureMapSizeSmall = 10
    
    /* The feature map size at output layer 2 = 10 x 10 which
     * which is 300 / 10 ~ 32 to make the math simpler
    */
    static let shrinkageBig = 32
    
    /* The feature map size at output layer 1 = 19 x 19 which
     * which is 300 / 19 ~ 16 to make the math simpler
     */
    static let shrinkageSmall = 16
    /* For each box, the height and width are multiplied
     * by square root of multiple aspect ratios, we use 2 and 3
     */
    static let aspectRatioOne = 2
    static let aspectRationTwo = 3
    
    /* For each activation, since we have 2 aspect ratios,
     * combined with height, and width, this yields a total of
     * 4 combinations of rectangular boxes, we further add two square
     * boxes to make the total number of boxes per activation = 6
     */
    static let noOfPriorsPerLocation = 6
    
    /* For each activation as described above we add two square bounding
     * boxes of size 60, 105 for output layer 1 and 105 and 150 for output
     * layer 2
     */
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
