//
//  SSDCreditCardOcr.swift
//  CardScan
//
//  Created by xaen on 5/15/20.
//
import UIKit

@available(iOS 11.2, *)
class SSDCreditCardOcr: CreditCardOcrImplementation {
    override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let image = croppedImageForSsd(fullCardImage: fullImage, roiRectangle: roiRectangle)
            else {
                return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
                
        let ocr = OcrDD()
        let startTime = Date()
        let number = ocr.perform(croppedCardImage: image)
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(image: image, number: number, expiryMonth: nil,
                                       expiryYear: nil, name: nil, computationTime: duration,
                                       numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
    }
}
