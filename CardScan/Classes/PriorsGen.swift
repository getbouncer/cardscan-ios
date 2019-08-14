//
//  PriorsGen.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation

struct PriorsGen{
    
    static func genPriors(featureMapSize: Int, shrinkage: Int, boxSizeMin: Int, boxSizeMax: Int, aspectRatioOne : Int, aspectRatioTwo: Int, noOfPriors: Int) -> [[Float]]{
        
        var boxes: [[Float]] = [[Float]](repeating: [Float](repeating: 0.0, count: 4), count: featureMapSize*featureMapSize*noOfPriors)
        var x_center: Float; var y_center: Float ; let image_size: Int = 300;
        var size: Float;
        let scale: Float = Float(image_size) / Float(shrinkage);
        var h: Float; var w: Float;
        var priorIndex: Int = 0; var ratioOne: Float; var ratioTwo: Float;
        
        for j in 0..<featureMapSize{
            for i in 0..<featureMapSize{
                x_center = (Float(i) + 0.5) / scale
                y_center = (Float(j) + 0.5) / scale
                
                size = Float(boxSizeMin)
                h = size / Float(image_size)
                w = size / Float(image_size)
                
                boxes[priorIndex][0] = x_center
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h;
                boxes[priorIndex][3] = w;
                
                priorIndex += 1
                
                size = sqrt(Float(boxSizeMax) * Float(boxSizeMin))
                h = size / Float(image_size)
                w = size / Float(image_size)
                
                boxes[priorIndex][0] = x_center
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h;
                boxes[priorIndex][3] = w;
                
                priorIndex += 1
                
                size = Float(boxSizeMin)
                h = size / Float(image_size)
                w = size / Float(image_size)
               
                ratioOne = sqrt(Float(aspectRatioOne))
                ratioTwo = sqrt(Float(aspectRatioTwo))
                
                boxes[priorIndex][0] = x_center;
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h * ratioOne;
                boxes[priorIndex][3] = w / ratioOne;
                priorIndex += 1
                
                boxes[priorIndex][0] = x_center;
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h / ratioOne;
                boxes[priorIndex][3] = w * ratioOne;
                priorIndex += 1
                
                boxes[priorIndex][0] = x_center;
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h * ratioTwo;
                boxes[priorIndex][3] = w / ratioTwo;
                priorIndex += 1
                
                boxes[priorIndex][0] = x_center;
                boxes[priorIndex][1] = y_center;
                boxes[priorIndex][2] = h / ratioTwo;
                boxes[priorIndex][3] = w * ratioTwo;
                priorIndex += 1
            }
        }
        return boxes
    }
    
    static func clamp(value: Float, minimum: Float, maximum: Float) -> Float{
        return max(minimum, min(maximum, value))
    }
    
    static func combinePriors() -> [[Float]]{

        let priorsOne = PriorsGen.genPriors(featureMapSize: 19, shrinkage: 16, boxSizeMin: 60, boxSizeMax: 105, aspectRatioOne: 2, aspectRatioTwo: 3, noOfPriors: 6)
        let priorsTwo = PriorsGen.genPriors(featureMapSize: 10, shrinkage: 32, boxSizeMin: 105, boxSizeMax: 150, aspectRatioOne: 2, aspectRatioTwo: 3, noOfPriors: 6)
        
        var priorsCombined: [[Float]] = [[Float]](repeating: [Float](repeating: 0.0, count: 4), count: priorsOne.count + priorsTwo.count)
        
        for i in 0..<priorsOne.count{
            for j in 0..<priorsOne[0].count{
                priorsCombined[i][j] = PriorsGen.clamp(value: priorsOne[i][j], minimum: 0.0, maximum: 1.0)
            }
        }
        for i in 0..<priorsTwo.count{
            for j in 0..<priorsTwo[0].count{
                priorsCombined[i+priorsOne.count][j] = PriorsGen.clamp(value: priorsTwo[i][j], minimum: 0.0, maximum: 1.0)
            }
        }
        
        return priorsCombined
        
        
    }
}
