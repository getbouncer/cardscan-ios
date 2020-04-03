//
//  SSDOcrOutputExtensions.swift
//  CardScan
//
//  Created by xaen on 3/22/20.
//

import Foundation
import Accelerate

@available(iOS 11.2, *)
extension SSDOcrOutput{
    
    /* ------------------------------ more complex getscores function ------------------------
    
    func getScores() -> ([[Float]], [[Float]]) {
        let pointerScores = UnsafeMutablePointer<Float>(OpaquePointer(self.scores.dataPointer))
        let pointerBoxes = UnsafeMutablePointer<Float>(OpaquePointer(self.boxes.dataPointer))
        let pointerFilter = UnsafeMutablePointer<Float>(OpaquePointer(self._597.dataPointer))
        let numOfRowsScores = self.scores.shape[3].intValue
        let numOfColsScores = self.scores.shape[4].intValue
        let numOfRowsBoxes = self.boxes.shape[3].intValue
        let numOfColsBoxes = self.boxes.shape[4].intValue
        let numOfRowsFilter = self._597.shape[3].intValue
        var filterArray = [Float](repeating: 0.0, count: numOfRowsFilter)
        var numToKeep : Int = 0
        
        for idx3 in 0..<self._597.count{
            let offsetFilter = idx3 * self._597.strides[4].intValue
            filterArray[idx3] = Float(pointerFilter[offsetFilter])
            if filterArray[idx3] > 0.25{
                numToKeep = numToKeep + 1
            }
        }
        
        var scoresTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfColsScores ), count: numToKeep)
        var boxesTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfColsBoxes ), count: numToKeep)
        
        var countScores = 0
        var countBoxes = 0
        var scoresI = 0
        var scoresJ = 0
        var boxesI = 0
        var boxesJ = 0
        for idx2 in 0..<self._597.count{
            if filterArray[idx2] > 0.25 {
                scoresJ = 0
                boxesJ = 0
                
                for idx in countScores..<countScores + numOfColsScores{
                    let offset = idx * self.scores.strides[4].intValue
                    scoresTest[scoresI][scoresJ] = Float(pointerScores[offset])
                    scoresJ = scoresJ + 1
                    }
                countScores = countScores + numOfColsScores
                scoresI = scoresI + 1
                
                for idx in countBoxes..<countBoxes + numOfColsBoxes{
                    let offset = idx * self.boxes.strides[4].intValue
                    boxesTest[boxesI][boxesJ] = Float(pointerBoxes[offset])
                    boxesJ = boxesJ + 1
                }
                countBoxes = countBoxes + numOfColsBoxes
                boxesI = boxesI + 1
                
            }
            
            else {
                countScores = countScores + numOfColsScores
                countBoxes = countBoxes + numOfColsBoxes
            }

        }
        return (scoresTest, boxesTest)
    }
 
    */
    
    func getScores(filterThreshold: Float) -> ([[Float]], [[Float]], [Float]) {
        let pointerScores = UnsafeMutablePointer<Float>(OpaquePointer(self.scores.dataPointer))
        let pointerBoxes = UnsafeMutablePointer<Float>(OpaquePointer(self.boxes.dataPointer))
        let pointerFilter = UnsafeMutablePointer<Float>(OpaquePointer(self._594.dataPointer))
        let numOfRowsScores = self.scores.shape[3].intValue
        let numOfColsScores = self.scores.shape[4].intValue
        var scoresTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfColsScores ), count: numOfRowsScores)
        let numOfRowsBoxes = self.boxes.shape[3].intValue
        let numOfColsBoxes = self.boxes.shape[4].intValue
        var boxesTest = [[Float]](repeating: [Float](repeating: 0.0, count: numOfColsBoxes ), count: numOfRowsBoxes)
        var filterArray = [Float](repeating: 0.0, count: numOfRowsScores)
       
        for idx3 in 0..<self._594.count{
           let offsetFilter = idx3 * self._594.strides[4].intValue
           filterArray[idx3] = Float(pointerFilter[offsetFilter])
           
       }

        var countScores = 0
        var countBoxes = 0
        for idx2 in 0..<self._594.count{
            if filterArray[idx2] > filterThreshold {

                for idx in countScores..<countScores + numOfColsScores{
                    let offset = idx * self.scores.strides[4].intValue
                    scoresTest[idx/numOfColsScores][idx%numOfColsScores] = Float(pointerScores[offset])
                    }
                countScores = countScores + numOfColsScores

                for idx in countBoxes..<countBoxes + numOfColsBoxes{
                    let offset = idx * self.boxes.strides[4].intValue
                    boxesTest[idx/numOfColsBoxes][idx%numOfColsBoxes] = Float(pointerBoxes[offset])
                }
                countBoxes = countBoxes + numOfColsBoxes

            }

            else {
                countScores = countScores + numOfColsScores
                countBoxes = countBoxes + numOfColsBoxes
            }

        }
        return (scoresTest, boxesTest, filterArray)
    }
    
    
    
    /*
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
 */

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
    
     /* These layers are also moved to the GPU
     
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
    */
    
    func convertLocationsToBoxes(locations: [[Float]], priors: [CGRect], centerVariance: Float,
                                 sizeVariance : Float) -> [[Float]]{
        
        /** Convert regressional location results of
         SSD into boxes in the form of (center_x, center_y, h, w)
         */
        var boxes = [[Float]]()
        
        for i in 0..<locations.count{
            let box = [locations[i][0] * centerVariance * Float(priors[i].width) + Float(priors[i].minX),
                       locations[i][1] * centerVariance * Float(priors[i].height) + Float(priors[i].minY),
                       exp(locations[i][2] * sizeVariance) * Float(priors[i].width),
                       exp(locations[i][3] * sizeVariance) * Float(priors[i].height)]
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
   
    func filterScoresAndBoxes( scores: [[Float]], boxes: [[Float]],
                               filterArray: [Float], filterThreshold: Float) -> ([[Float]], [[Float]]) {
        
        var prunnedScores = [[Float]]()
        var prunnedBoxes = [[Float]]()
        
        for i in 0..<filterArray.count {
            if filterArray[i] > filterThreshold{
                prunnedScores.append(scores[i])
                prunnedBoxes.append(boxes[i])
            }
        }
        
        return (prunnedScores, prunnedBoxes)
    }
}
