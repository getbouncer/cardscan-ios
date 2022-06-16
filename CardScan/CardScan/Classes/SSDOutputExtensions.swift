//
//  SSDOutputExtensions.swift
//  CardScan
//
//  Created by Zain on 8/5/19.
//

import Foundation
import Accelerate

@available(iOS 11.2, *)
@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
extension SSDOutput{


    func getScores() -> [[Float]] {
        let pointer = UnsafeMutablePointer<Float>(OpaquePointer(self.scores.dataPointer))
        let numOfRows = self.scores.shape[3].intValue
        let numOfCols = self.scores.shape[4].intValue
        var scoresTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfCols ), count: numOfRows)
        for idx in 0..<self.scores.count{
            
            let offset = idx * self.scores.strides[4].intValue
            scoresTest[idx/numOfCols][idx%numOfCols] = Float(pointer[offset])
        }
        return scoresTest
    }

    func getBoxes() ->[[Float]]{
        let pointer = UnsafeMutablePointer<Float>(OpaquePointer(self.boxes.dataPointer))
        let numOfRows = self.boxes.shape[3].intValue
        let numOfCols = self.boxes.shape[4].intValue
        var boxesTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfCols ), count: numOfRows)
        for idx in 0..<self.boxes.count{
            
            let offset = idx * self.boxes.strides[4].intValue
            boxesTest[idx/numOfCols][idx%numOfCols] = Float(pointer[offset])
        }
        return boxesTest
    }

    
    func matrixReshape(_ nums: [[Float]], _ r: Int, _ c: Int) -> [[Float]] {
        
        var resultArray:[[Float]] = Array.init()
        var elementArray:[Float] = Array.init()
        var elementCount:Int = 0;
        for firstArray in nums
        {
            for val in firstArray
            {
                elementArray.append(val)
                if(elementArray.count>=c)
                {
                    resultArray.append(elementArray)
                    elementArray.removeAll()
                }
                elementCount = elementCount+1
            }
        }
        if(elementCount != r * c)
        {
            resultArray = nums
        }
        return resultArray
    }
    

     func softmax(_ x: [Float]) -> [Float] {
        // subtract the max from each value
        // to prevent exp blowup
        // raise all elements to power e
        // and divide by the sum
        
        var x = x
        let len = vDSP_Length(x.count)
        var max: Float = 0
        vDSP_maxv(x, 1, &max, len)
        
        max = -max
        vDSP_vsadd(x, 1, &max, &x, 1, len)
        
        var count = Int32(x.count)
        vvexpf(&x, x, &count)
        
        var sum: Float = 0
        vDSP_sve(x, 1, &sum, len)
        vDSP_vsdiv(x, 1, &sum, &x, 1, len)
        
        return x
    }
    
    func fasterSoftmax2D(_ scores: [[Float]]) -> [[Float]]{
       
        let normalizedScores = scores.map {softmax($0)}
        return normalizedScores
    }
    
    func convertLocationsToBoxes(locations: [[Float]], priors: [CGRect], centerVariance: Float, sizeVariance : Float) -> [[Float]]{
        
        /** Convert regressional location results of
         SSD into boxes in the form of (center_x, center_y, h, w)
         */
        var boxes = [[Float]]()
        
        for i in 0..<locations.count{
            let box = [locations[i][0] * centerVariance * Float(priors[i].height) + Float(priors[i].minX),
                       locations[i][1] * centerVariance * Float(priors[i].width) + Float(priors[i].minY),
                       exp(locations[i][2] * sizeVariance) * Float(priors[i].height),
                       exp(locations[i][3] * sizeVariance) * Float(priors[i].width)]
            boxes.append(box)
        }
        
        return boxes
    }
    func centerFormToCornerForm( regularBoxes: [[Float]]) -> [[Float]]{
        
        /** Convert center from (center_x, center_y, h, w) to
         * corner form XMin, YMin, XMax, YMax
         */
        var cornerFormBoxes = regularBoxes
        for i in 0..<regularBoxes.count{
            for j in 0..<2{
            cornerFormBoxes[i][j] = regularBoxes[i][j] - regularBoxes[i][j+2]/2
            cornerFormBoxes[i][j+2] = regularBoxes[i][j] + regularBoxes[i][j+2]/2
            }
        }
        return cornerFormBoxes
    }
    
}
