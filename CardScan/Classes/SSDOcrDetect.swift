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
    static var ssdOcrModel: SSDOcr? = nil
    static var priors: [CGRect]? = nil
    
    //SSD Model parameters
    let ssdOcrImageWidth = 600
    let ssdOcrImageHeight = 375
    let probThreshold: Float = 0.5
    let iouThreshold: Float = 0.45
    let centerVariance: Float = 0.1
    let sizeVariance: Float = 0.2
    let candidateSize = 200
    let topK = 20
    
    
    func warmUp() {
        SSDOcrDetect.initializeModels()
        UIGraphicsBeginImageContext(CGSize(width: ssdOcrImageWidth,
                                           height: ssdOcrImageHeight))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: ssdOcrImageWidth,
                                      height: ssdOcrImageHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let ssdOcrModel = SSDOcrDetect.ssdOcrModel else{
            print("Model not initialized")
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
    }
    
    static func initializeModels() {
        if SSDOcrDetect.ssdOcrModel == nil{
            SSDOcrDetect.ssdOcrModel = SSDOcr()
        }
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
    }
    public static func isModelLoaded() -> Bool {
        return self.ssdOcrModel != nil
    }
    
    func detectOcrObjects(prediction: SSDOcrOutput, image: UIImage) -> DetectedAllOcrBoxes {
        var DetectedOcrBoxes = DetectedAllOcrBoxes()
        var startTime = CFAbsoluteTimeGetCurrent()
        let boxes = prediction.getBoxes()
        let scores = prediction.getScores()
        var endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "Get boxes and scores from mult-array time: \(endTime)")
    
        startTime = CFAbsoluteTimeGetCurrent()
        let normalizedScores = prediction.fasterSoftmax2D(scores)
        let regularBoxes = prediction.convertLocationsToBoxes(locations: boxes, priors: SSDOcrDetect.priors ?? OcrPriorsGen.combinePriors(), centerVariance: 0.1, sizeVariance: 0.2)
        let cornerFormBoxes = prediction.centerFormToCornerForm(regularBoxes: regularBoxes)

        let predAPI = PredictionAPI()
        let result:Result = predAPI.predictionAPI(scores:normalizedScores, boxes: cornerFormBoxes, probThreshold: SsdDetect.probThreshold, iouThreshold: SsdDetect.iouThreshold, candidateSize: SsdDetect.candidateSize, topK: SsdDetect.topK)
        endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "Rest of the forward pass time: \(endTime)")
    
        for idx in 0..<result.pickedBoxes.count {
            DetectedOcrBoxes.allBoxes.append(DetectedSSDOcrBox(category: result.pickedLabels[idx], conf: result.pickedBoxProbs[idx], XMin: Double(result.pickedBoxes[idx][0]), YMin: Double(result.pickedBoxes[idx][1]), XMax: Double(result.pickedBoxes[idx][2]), YMax: Double(result.pickedBoxes[idx][3]), imageSize: image.size))
        }
        
        let leftCordinates = result.pickedBoxes.map{$0[0]}
        let sortedLeftCordinates = leftCordinates.enumerated().sorted(by: {$0.element < $1.element})
        let indices = sortedLeftCordinates.map{$0.offset}
        var _cardNumber: String = ""

        indices.forEach { index in
            if result.pickedLabels[index] == 10{
                _cardNumber = _cardNumber + String(0)
            }
            else {
                _cardNumber = _cardNumber + String(result.pickedLabels[index])
            }
        }
        //print(cardNumber)
        if CreditCardUtils.isValidNumber(cardNumber: _cardNumber){
            print(_cardNumber)
            //self.CardNumber = _cardNumber
            //return DetectedSSDBoxes
        }
        return DetectedOcrBoxes
    }

    public func predict(image: UIImage) -> DetectedAllOcrBoxes? {
        guard let pixelBuffer = image.pixelBuffer(width: ssdOcrImageWidth,
                                                  height: ssdOcrImageHeight)
        else {
            os_log("Couldn't convert to pixel buffer", type: .debug)
            return nil
                                                    
        }
        
        guard let ocrDetectModel = SSDOcrDetect.ssdOcrModel else {
            os_log("Model not initialized", type: .debug)
            return nil
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let input = SSDOcrInput(_0: pixelBuffer)
        
        guard let prediction = try? ocrDetectModel.prediction(input: input) else {
            os_log("Couldn't predict", type: .debug)
            return nil
        }
        
        let endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "Model Run without post-process time: \(endTime)")
        
        return self.detectOcrObjects(prediction: prediction, image: image)

    }
}
