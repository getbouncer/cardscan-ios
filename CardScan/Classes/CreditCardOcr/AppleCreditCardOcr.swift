//
//  AppleCreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

@available(iOS 13.0, *)
class AppleCreditCardOcr: CreditCardOcrImplementation {
    override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let image = croppedImage(fullCardImage: fullImage, roiRectangle: roiRectangle) else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
        
        var pan: String?
        var expiryMonth: String?
        var expiryYear: String?
        let semaphore = DispatchSemaphore(value: 0)
        let startTime = Date()
        var name: String?
        var nameBox: CGRect?
        var numberBox: CGRect?
        var expiryBox: CGRect?
        AppleOcr.recognizeText(in: image) { results in
            for result in results {
                let predictedPan = CreditCardOcrPrediction.pan(result.text)
                let expiry = CreditCardOcrPrediction.likelyExpiry(result.text)
                if let (month, year) = expiry {
                    if CreditCardUtils.isValidDate(expMonth: month, expYear: year) {
                        print("expiry \(expiry) confidence \(result.confidence)")
                        if expiryMonth == nil {
                            expiryBox = result.rect
                            expiryMonth = month
                        }
                        if expiryYear == nil { expiryYear = year }
                    }
                }
                if pan == nil {
                    pan = predictedPan
                    numberBox = result.rect
                }
                
                let nameReferenceBox = expiryBox ?? numberBox ?? CGRect(x: 0, y: 0, width: image.width, height: image.height)
                let predictedName = AppleCreditCardOcr.likelyName(result.text)
                if predictedName != nil {
                    print("\(predictedName!) \(result.rect.minY) >= \(nameReferenceBox.maxY)")
                }
                // XXX FIXME we should be smarter about the name
                if name == nil && result.confidence >= 0.5 && result.rect.minY >= (nameReferenceBox.maxY - 5.0) {
                    name = predictedName
                    nameBox = result.rect
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1

        return CreditCardOcrPrediction(image: image, number: pan, expiryMonth: expiryMonth, expiryYear: expiryYear, name: name, computationTime: duration, numberBoxes: numberBox.map { [$0] }, expiryBoxes: expiryBox.map { [$0] }, nameBoxes: nameBox.map { [$0] })
    }
    
    static func likelyName(_ text: String) -> String? {
        let words = text.split(separator: " ").map { String($0) }
        let validWords = words.filter { !NameWords.nonNameWordMatch($0) && NameWords.onlyLettersAndSpaces($0) }
        let validWordCount = validWords.count >= 2
        
        return validWordCount ? validWords.joined(separator: " ") : nil
    }
}
