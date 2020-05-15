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
        guard let image = croppedImageForSsd(fullCardImage: fullImage, roiRectangle: roiRectangle),
            let squareImage = CreditCardOcrImplementation.squareCardImage(fullCardImage: fullImage,
                                                                          roiRectangle: roiRectangle)
            else {
                return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
                
        let ocr = OcrDD()
        let ux = UXWrapper()
        let startTime = Date()
        let _ = ux.perform(croppedCardImage: image)
        let number = ocr.perform(croppedCardImage: image)
        let duration = -startTime.timeIntervalSinceNow
        print("DEBUG: Inference time for DD Ocr and UX Serial: ", duration)
        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(image: image, number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: duration, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
    }
}
