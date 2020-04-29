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
            return CreditCardOcrPrediction(number: nil, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0)
        }
        
        var pan: String?
        var expiryMonth: String?
        var expiryYear: String?
        let semaphore = DispatchSemaphore(value: 0)
        let startTime = Date()
        var name: String?
        AppleOcr.recognizeText(in: image) { results in
            for result in results {
                let predictedPan = CreditCardOcrPrediction.pan(result.text)
                let expiry = CreditCardOcrPrediction.likelyExpiry(result.text)
                if let (month, year) = expiry {
                    if CreditCardUtils.isValidDate(expMonth: month, expYear: year) {
                        if expiryMonth == nil { expiryMonth = month }
                        if expiryYear == nil { expiryYear = year }
                    }
                }
                if pan == nil { pan = predictedPan }
                let predictedName = AppleCreditCardOcr.likelyName(result.text)
                name = {
                    switch (name, predictedName) {
                    case (.some(let name), .some(let predictedName)):
                        return name + "\n" + predictedName
                    case (.none, .some(let predictedName)):
                        return predictedName
                    case (.some(let name), .none):
                        return name
                    case (.none, .none):
                        return nil
                    }
                }()
            }
            semaphore.signal()
        }
        semaphore.wait()
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1

        return CreditCardOcrPrediction(number: pan, expiryMonth: expiryMonth, expiryYear: expiryYear, name: name, computationTime: duration)
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
