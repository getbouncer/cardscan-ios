//
//  UXCreditCardDetect.swift
//  CardScan
//
//  Created by xaen on 5/15/20.
//

import UIKit

@available(iOS 11.2, *)
class UXCreditCardDetect: CreditCardOcrImplementation {
    override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let image = croppedImageWithFullWidth(fullCardImage: fullImage, roiRectangle: roiRectangle),
            let squareImage = CreditCardOcrImplementation.squareCardImage(fullCardImage: fullImage, roiRectangle: roiRectangle) else {
                return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
                
        let ux = UXWrapper()
        let startTime = Date()
        let number = ux.perform(croppedCardImage: image)
        let duration = -startTime.timeIntervalSinceNow
        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(image: image, number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: duration, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
    }
}
