//
//  PredictionUtilOcr.swift
//  CardScan
//
//  Created by xaen on 6/4/20.
//

import Foundation

struct PredictionUtilOcr{
    
    /**
     * A utitliy struct that applies non-max supression to each class
     * picks out the remaining boxes, the class probabilities for classes
     * that are kept and composes all the information in one place to be returned as
     * an object.
     */
    func predictionUtil(scores: [[Float]], boxes: [[Float]], probThreshold: Float,
                       iouThreshold: Float, candidateSize: Int , topK: Int) -> Result{
        var pickedBoxes:[[Float]] = [[Float]]()
        var pickedLabels:[Int] = [Int]()
        var pickedBoxProbs:[Float] = [Float]()
        
        
        for classIndex in 0..<scores[0].count{
            var probs: [Float] = [Float]()
            var subsetBoxes: [[Float]] = [[Float]]()
            //var indicies : [Int] = [Int]()
            
            for rowIndex in 0..<scores.count{
                if scores[rowIndex][classIndex] > probThreshold{
                    probs.append(scores[rowIndex][classIndex])
                    subsetBoxes.append(boxes[rowIndex])
                }
            }
            
            if probs.count == 0{
                continue
            }
            
            var _pickedBoxes = [[Float]]()
            var _pickedScores = [Float]()

            if #available(iOS 11.2, *) {
                (_pickedBoxes, _pickedScores) = SoftNMS.softNMS(subsetBoxes: subsetBoxes, probs: probs,
                                                                probThreshold: probThreshold, sigma: SSDOcrDetect.sigma, topK: topK,
                                                                candidateSize: candidateSize)
            } else {
                // Fallback on earlier versions
            }

            for idx in 0..<_pickedScores.count{
                pickedBoxProbs.append(_pickedScores[idx])
                pickedBoxes.append(_pickedBoxes[idx])
                pickedLabels.append((classIndex + 1) % 10)
            }
        
        }
        var result: Result = Result()
        result.pickedBoxProbs =  pickedBoxProbs
        result.pickedLabels = pickedLabels
        result.pickedBoxes = pickedBoxes
        
        return result
        
    }
    
}
