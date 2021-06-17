//
//  AppleCreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

@available(iOS 13.0, *)
public class AppleCreditCardOcr: CreditCardOcrImplementation {
    public override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let (image, roiForOcr) = fullImage.croppedImageForSsd(roiRectangle: roiRectangle) else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
        
        var pan: String?
        var expiryMonth: String?
        var expiryYear: String?
        let semaphore = DispatchSemaphore(value: 0)
        let startTime = Date()
        var name: String?
        var nameBox: CGRect?
        var numberBoxes: [CGRect]?
        var numberBox: CGRect?
        var expiryBox: CGRect?
        var nameCandidates: [OcrObject] = []
        AppleOcr.recognizeText(in: image) { results in
            for result in results {
                let predictedPan = CreditCardOcrPrediction.pan(result.text)
                let expiry = CreditCardOcrPrediction.likelyExpiry(result.text)
                if let (month, year) = expiry {
                    if CreditCardUtils.isValidDate(expMonth: month, expYear: year) {
                        if expiryMonth == nil {
                            expiryBox = result.rect
                            expiryMonth = month
                        }
                        if expiryYear == nil { expiryYear = year }
                    }
                }
                if pan == nil && predictedPan != nil {
                    pan = predictedPan
                    numberBox = result.rect
                }
                
                let predictedName = AppleCreditCardOcr.likelyName(result.text)
                if predictedName != nil {
                    nameCandidates.append(result)
                }
            }
            
            let minY = numberBox.map({ $0.minY - $0.height}) ?? expiryBox?.minY
            let names = nameCandidates.filter { name in
                let isInExpectedLocation = minY.map({ name.rect.minY >= ($0 - 5.0) }) ?? false
                return name.confidence >= 0.5 && isInExpectedLocation
            }
            
            // just pick the first one for now
            if let nameResult = names.first {
                name = AppleCreditCardOcr.likelyName(nameResult.text)
                nameBox = nameResult.rect
            }
            
            semaphore.signal()
        }
        semaphore.wait()
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1

        if let somePan = pan, let someNumberBox = numberBox {
            numberBoxes = extractBoxes(number: somePan, numberBox: someNumberBox)
        }
        
        return CreditCardOcrPrediction(image: image, ocrCroppingRectangle: roiForOcr, number: pan, expiryMonth: expiryMonth, expiryYear: expiryYear, name: name, computationTime: duration, numberBoxes: numberBoxes, expiryBoxes: expiryBox.map { [$0] }, nameBoxes: nameBox.map { [$0] })
    }
    
    static func likelyName(_ text: String) -> String? {
        let words = text.split(separator: " ").map { String($0) }
        let validWords = words.filter { !NameWords.nonNameWordMatch($0) && NameWords.onlyLettersAndSpaces($0) }
        let validWordCount = validWords.count >= 2
        
        return validWordCount ? validWords.joined(separator: " ") : nil
    }
    
    func isSpace(digits: Int, index: Int) -> Bool {
        if index == 4 {
            return true
        }
        
        if digits == 17 && index == 11 {
            return true
        }
        
        if digits == 19 && index == 9 {
            return true
        }
        
        if digits == 19 && index == 14 {
            return true
        }
        
        return false
    }
    
    func extractBoxes(number: String, numberBox: CGRect) -> [CGRect] {
        let digits = number.count == 15 ? 17 : 19
        let width = Double(numberBox.size.width) / Double(digits)
        let height = Double(numberBox.size.height)
        var x = Double(numberBox.origin.x)
        let y = Double(numberBox.minY)
        var rects: [CGRect] = []
        for index in 0..<digits {
            if !isSpace(digits: digits, index: index) {
                rects.append(CGRect(x: x, y: y, width: width, height: height))
            }
            x += width
        }
        return rects
    }
}
