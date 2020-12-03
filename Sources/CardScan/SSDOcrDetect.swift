//
//  SSDOcrDetect.swift
//  CardScan
//
//  Created by xaen on 3/21/20.
//

import Foundation
import os.log

/** Documentation for SSD OCR
 
 */

@available(iOS 11.2, *)

struct SSDOcrDetect {
    var ssdOcrModel: SSDOcr? = nil
    static var priors: [CGRect]? = nil
    
    static var ssdOcrResource = "SSDOcr"
    static let ssdOcrExtension = "mlmodelc"
    
    //SSD Model parameters
    static let sigma: Float = 0.5
    let ssdOcrImageWidth = 600
    let ssdOcrImageHeight = 375
    let probThreshold: Float = 0.45
    let filterThreshold: Float = 0.39
    let iouThreshold: Float = 0.5
    let centerVariance: Float = 0.1
    let sizeVariance: Float = 0.2
    let candidateSize = 200
    let topK = 20
    
    //Statistics about last prediction
    var lastDetectedBoxes: [CGRect] = []
    
    
    func warmUp() {
        SSDOcrDetect.initializeModels()
        UIGraphicsBeginImageContext(CGSize(width: ssdOcrImageWidth,
                                           height: ssdOcrImageHeight))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: ssdOcrImageWidth,
                                      height: ssdOcrImageHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let ssdOcrModel = ssdOcrModel else{
            print("OCR Model not initialized")
            return
        }
        if let pixelBuffer = newImage?.pixelBuffer(width: ssdOcrImageWidth,
                                                   height: ssdOcrImageHeight){
            let input = SSDOcrInput(_0: pixelBuffer)
            let _ = try? ssdOcrModel.prediction(input: input)
        }
    }
    
    public init() {
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
        guard let ssdOcrUrl  = CSBundle.compiledModel(forResource: SSDOcrDetect.ssdOcrResource, withExtension: SSDOcrDetect.ssdOcrExtension) else {

            print("Could not find URL for ssd ocr")
            return
        }
        
        guard let ssdOcrModel = try? SSDOcr(contentsOf: ssdOcrUrl) else {
            print("Could not get contents of ssd ocr model with ssd ocr URL")
            return
        }
        
        self.ssdOcrModel = ssdOcrModel
    }
    
    static func initializeModels() {
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
    }
    
    mutating func detectOcrObjects(prediction: SSDOcrOutput, image: UIImage) -> String? {
        var DetectedOcrBoxes = DetectedAllOcrBoxes()
        
        var scores : [[Float]]
        var boxes : [[Float]]
        var filterArray : [Float]

        (scores, boxes, filterArray) = prediction.getScores(filterThreshold: filterThreshold)
        let regularBoxes = prediction.convertLocationsToBoxes(locations: boxes,
                                                              priors: SSDOcrDetect.priors ?? OcrPriorsGen.combinePriors(),
                                                              centerVariance: 0.1, sizeVariance: 0.2)
        let cornerFormBoxes = prediction.centerFormToCornerForm(regularBoxes: regularBoxes)
        
        var prunnedScores : [[Float]]
        var prunnedBoxes : [[Float]]
        
        (prunnedScores, prunnedBoxes) = prediction.filterScoresAndBoxes(scores: scores,
                                                                         boxes: cornerFormBoxes,
                                                                         filterArray:  filterArray,
                                                                         filterThreshold: filterThreshold)
        
        if prunnedScores.isEmpty || prunnedBoxes.isEmpty{
            prunnedScores = [[Float]](repeating: [Float](repeating: 0.0, count: 2), count: 2)
            prunnedBoxes = [[Float]](repeating: [Float](repeating: 0.0, count: 2 ), count: 2)
            
        }
        
        let predUtil = PredictionUtilOcr()
        let result:Result = predUtil.predictionUtil(scores:prunnedScores, boxes: prunnedBoxes,
                                                  probThreshold: probThreshold,
                                                  iouThreshold: iouThreshold,
                                                  candidateSize: candidateSize,
                                                  topK: topK)
    
        for idx in 0..<result.pickedBoxes.count {
            DetectedOcrBoxes.allBoxes.append(DetectedSSDOcrBox(category: result.pickedLabels[idx], conf: result.pickedBoxProbs[idx],
                                                               XMin: Double(result.pickedBoxes[idx][0]), YMin: Double(result.pickedBoxes[idx][1]),
                                                               XMax: Double(result.pickedBoxes[idx][2]), YMax: Double(result.pickedBoxes[idx][3]),
                                                               imageSize: image.size))
        }
        
        if !DetectedOcrBoxes.allBoxes.isEmpty {
            self.lastDetectedBoxes = DetectedOcrBoxes.getBoundingBoxesOfDigits()
        }
        
        if OcrDDUtils.isQuickRead(allBoxes: DetectedOcrBoxes){
            return OcrDDUtils.processQuickRead(allBoxes: DetectedOcrBoxes)
        }
        else {
            return OcrDDUtils.sortAndRemoveFalsePositives(allBoxes: DetectedOcrBoxes)
        }
        
        
    }

    public mutating func predict(image: UIImage) -> String? {
        
        SSDOcrDetect.initializeModels()
        guard let pixelBuffer = image.pixelBuffer(width: ssdOcrImageWidth,
                                                  height: ssdOcrImageHeight)
        else {
            os_log("Couldn't convert to pixel buffer", type: .debug)
            return nil
                                                    
        }
        
        guard let ocrDetectModel = ssdOcrModel else {
            os_log("Ocr Model not initialized", type: .debug)
            return nil
        }
        
        let input = SSDOcrInput(_0: pixelBuffer)
        
        guard let prediction = try? ocrDetectModel.prediction(input: input) else {
            os_log("Ocr Couldn't predict", type: .debug)
            return nil
        }
        return self.detectOcrObjects(prediction: prediction, image: image)
    }
}
