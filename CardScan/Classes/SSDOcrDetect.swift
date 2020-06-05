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
                print("Could not find URL for ssd ocr")
                return
            }
    
            guard let ssdOcrModel = try? SSDOcr(contentsOf: ssdOcrUrl) else {
                print("Could not get contents of ssd ocr model with ssd ocr URL")
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
        
        if self.isQuickRead(allBoxes: DetectedOcrBoxes){
            let _cardNumber = processQuickRead(allBoxes: DetectedOcrBoxes)
            return _cardNumber
        }
        else {
            //os_log("%@", type: .error, "Not Quick Read")
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
                    //os_log("%@" , type: .debug, "Could verify \(_cardNumber)")
            }
        }
        return nil
    }
   
    func processQuickRead(allBoxes: DetectedAllOcrBoxes) -> String? {
        var _cardNumber: String = ""
        let sortedBoxes = allBoxes.allBoxes.sorted(by: {($0.rect.minY / 2 + $0.rect.maxY / 2)
                                                            < ($1.rect.minY / 2 + $1.rect.maxY / 2)})
        
        var groupSlice = sortedBoxes[..<4]
        var firstGroup = Array(groupSlice)
        firstGroup = firstGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
        
        for idx in 0..<firstGroup.count {
            _cardNumber = _cardNumber + String(firstGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[4..<8]
        var secondGroup = Array(groupSlice)
        secondGroup = secondGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
        
        for idx in 0..<secondGroup.count {
            _cardNumber = _cardNumber + String(secondGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[8..<12]
        var thirdGroup = Array(groupSlice)
        thirdGroup = thirdGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
       
        for idx in 0..<thirdGroup.count {
            _cardNumber = _cardNumber + String(thirdGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[12..<16]
        var fourthGroup = Array(groupSlice)
        fourthGroup = fourthGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
      
        for idx in 0..<fourthGroup.count {
            _cardNumber = _cardNumber + String(fourthGroup[idx].label)
        }
        
        if CreditCardUtils.isValidNumber(cardNumber: _cardNumber){
            print(_cardNumber)
            return _cardNumber
        }
        else {
            //os_log("%@" , type: .debug, "Could verify \(_cardNumber)")
        }
        return nil
        
    }
    
    func isQuickRead(allBoxes: DetectedAllOcrBoxes) -> Bool {
        if (allBoxes.allBoxes.isEmpty) || (allBoxes.allBoxes.count != 16) {
            //os_log("%@", type: .debug, "Failed in capacity:\(allBoxes.allBoxes.capacity)")
            return false
        }
        
        var boxCenters = [Float]()
        var boxHeights = [Float]()
        var aggregateDeviation: Float = 0
        
        for idx in 0..<allBoxes.allBoxes.count {
            boxCenters.append(Float((allBoxes.allBoxes[idx].rect.midY)))
            boxHeights.append(abs(Float(allBoxes.allBoxes[idx].rect.height)))
        }
        
        let medianYCenter = boxCenters.sorted(by: <)[boxCenters.count / 2]
        let medianHeight = boxHeights.sorted(by: <)[boxHeights.count / 2]
        
        for idx in 0..<boxCenters.count {
            aggregateDeviation += abs(medianYCenter - boxCenters[idx])
        }
        
        if (aggregateDeviation > 2.0 * medianHeight)
        {
            return true
        }
        return false
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
        
        let input = SSDOcrInput(_0: pixelBuffer)
        
        guard let prediction = try? ocrDetectModel.prediction(input: input) else {
            os_log("Couldn't predict", type: .debug)
            return nil
        }
        return self.detectOcrObjects(prediction: prediction, image: image)
    }
}
