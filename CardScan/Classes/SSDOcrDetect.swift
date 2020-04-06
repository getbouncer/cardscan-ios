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
    
    static let ssdOcrResource = "SSDOcr"
    static let ssdOcrExtension = "mlmodelc"
    
    //SSD Model parameters
    static let sigma: Float = 0.4
    let ssdOcrImageWidth = 600
    let ssdOcrImageHeight = 375
    let probThreshold: Float = 0.3
    let filterThreshold: Float = 0.29
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
        
        if SSDOcrDetect.ssdOcrModel == nil {
            guard let ssdOcrUrl  = CSBundle.compiledModel(forResource: ssdOcrResource, withExtension: ssdOcrExtension) else {
                print("Could not find URL for FourRecognize")
                return
            }
    
            guard let ssdOcrModel = try? SSDOcr(contentsOf: ssdOcrUrl) else {
                print("Could not get contents of recognize model with fourRecognize URL")
                return
            }
    
            SSDOcrDetect.ssdOcrModel = ssdOcrModel
        
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
    }
    }
    public static func isModelLoaded() -> Bool {
        return self.ssdOcrModel != nil
    }
    
    func detectOcrObjects(prediction: SSDOcrOutput, image: UIImage) -> String? {
        var DetectedOcrBoxes = DetectedAllOcrBoxes()
        
        var scores : [[Float]]
        var boxes : [[Float]]
        var filterArray : [Float]
        //var startTime = CFAbsoluteTimeGetCurrent()
        //var boxes = prediction.getBoxes()
        //var endTime = CFAbsoluteTimeGetCurrent() - startTime
        //os_log("%@", type: .debug, "Getboxes: \(endTime)")
        
        var startTime = CFAbsoluteTimeGetCurrent()
        (scores, boxes, filterArray) = prediction.getScores(filterThreshold: filterThreshold)
        var endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "Get scores and boxes from mult array: \(endTime)")
       
        /*
        if scores.isEmpty || boxes.isEmpty{
            scores = [[Float]](repeating: [Float](repeating: 0.0, count: 2), count: 2)
            boxes = [[Float]](repeating: [Float](repeating: 0.0, count: 2 ), count: 2)
        }
        */
        
        
        // The following layers have been moved to the GPU now
    
        startTime = CFAbsoluteTimeGetCurrent()
        //let normalizedScores = prediction.fasterSoftmax2D(scores)
        let regularBoxes = prediction.convertLocationsToBoxes(locations: boxes,
                                                              priors: SSDOcrDetect.priors ?? OcrPriorsGen.combinePriors(),
                                                              centerVariance: 0.1, sizeVariance: 0.2)
        let cornerFormBoxes = prediction.centerFormToCornerForm(regularBoxes: regularBoxes)
        endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "locations to boxes and center to corner form: \(endTime)")
        
        var prunnedScores : [[Float]]
        var prunnedBoxes : [[Float]]
        
        (prunnedScores, prunnedBoxes) = prediction.filterScoresAndBoxes(scores: scores,
                                                                         boxes: cornerFormBoxes,
                                                                         filterArray:  filterArray, filterThreshold: filterThreshold)
        
        if prunnedScores.isEmpty || prunnedBoxes.isEmpty{
            prunnedScores = [[Float]](repeating: [Float](repeating: 0.0, count: 2), count: 2)
            prunnedBoxes = [[Float]](repeating: [Float](repeating: 0.0, count: 2 ), count: 2)
            
        }
        startTime = CFAbsoluteTimeGetCurrent()
        let predAPI = PredictionAPI()
        let result:Result = predAPI.predictionAPI(scores:prunnedScores, boxes: prunnedBoxes,
                                                  probThreshold: probThreshold,
                                                  iouThreshold: iouThreshold,
                                                  candidateSize: candidateSize,
                                                  topK: topK)
        endTime = CFAbsoluteTimeGetCurrent() - startTime
        os_log("%@", type: .debug, "NMS: \(endTime)")
    
        for idx in 0..<result.pickedBoxes.count {
            DetectedOcrBoxes.allBoxes.append(DetectedSSDOcrBox(category: result.pickedLabels[idx], conf: result.pickedBoxProbs[idx], XMin: Double(result.pickedBoxes[idx][0]), YMin: Double(result.pickedBoxes[idx][1]), XMax: Double(result.pickedBoxes[idx][2]), YMax: Double(result.pickedBoxes[idx][3]), imageSize: image.size))
        }
        
        
        if (!result.pickedBoxes.isEmpty) {
                let topCordinates = result.pickedBoxes.map{$0[1]}
                let bottomCordinates = result.pickedBoxes.map{$0[3]}
        
                let medianYmin = topCordinates.sorted(by: <)[topCordinates.count / 2]
                let medianYmax = bottomCordinates.sorted(by: <)[bottomCordinates.count / 2]
        
                let medianHeight = abs(medianYmax - medianYmin)
                let medianCenter = (medianYmin + medianYmax) / 2
        
                let leftCordinates = result.pickedBoxes.map{$0[0]}
                let sortedLeftCordinates = leftCordinates.enumerated().sorted(by: {$0.element < $1.element})
                let indices = sortedLeftCordinates.map{$0.offset}
                var _cardNumber: String = ""

                indices.forEach { index in
                    // get the box
                    let box = result.pickedBoxes[index]
                    let boxCenter = abs(box[3] + box[1]) / 2
                    let boxHeight = abs(box[3] - box[1])
                    if abs(boxCenter - medianCenter) < medianHeight && boxHeight < 1.2 * medianHeight {
                            _cardNumber = _cardNumber + String(result.pickedLabels[index])
                    }
        
                }
                if CreditCardUtils.isValidNumber(cardNumber: _cardNumber){
                    print(_cardNumber)
                    return _cardNumber
                }
                else {
                    os_log("%@" , type: .debug, "Could verify \(_cardNumber)")
            }
            }
        
        return nil
    }

    public func predict(image: UIImage) -> String? {
        
        SSDOcrDetect.initializeModels()
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
