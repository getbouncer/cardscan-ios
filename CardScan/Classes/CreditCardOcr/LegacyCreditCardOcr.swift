//
//  LegacyCreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

@available(iOS 11.2, *)
class LegacyCreditCardOcr: CreditCardOcrImplementation {
    override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let image = croppedImageWithFullWidth(fullCardImage: fullImage, roiRectangle: roiRectangle),
            let squareImage = squareCardImage(fullCardImage: fullImage, roiRectangle: roiRectangle) else {
                return CreditCardOcrPrediction(number: nil, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0)
        }
                
        let ocr = Ocr()
        let startTime = Date()
        let number = ocr.perform(croppedCardImage: image, squareCardImage: squareImage, fullCardImage: fullImage)
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: duration)
    }
}
