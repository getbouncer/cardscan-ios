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
                let predictedName = AppleCreditCardOcr.likelyName(result.text)
                // XXX FIXME we should be smarter about the name
                if name == nil {
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
        let lettersAndSpace = text.reduce(true) { acc, value in
            let capitalLetter = value >= "A" && value <= "Z"
            // for now we're only going to accept upper case names
            //let lowerCaseLetter = value >= "a" && value <= "z"
            let space = value == " "
            return acc && (capitalLetter || space)
        }
        
        let words = text.split(separator: " ").map { String($0) }
        let containsBlacklistWord = words.reduce(false) { acc, value in
            return acc || NonNameWords.match(value)
        }
        
        let validWordCount = words.count == 2 || words.count == 3
        
        return lettersAndSpace && !containsBlacklistWord && validWordCount ? text : nil
    }
}
