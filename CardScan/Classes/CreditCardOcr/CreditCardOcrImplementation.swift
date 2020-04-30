//
//  CreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

/**
 Base class for any OCR prediction systems. All implementations must override `recognizeCard` and update the `frames`
 and `computationTime` member variables
 */

class CreditCardOcrImplementation {
    let dispatchQueue: DispatchQueue
    var frames = 0
    var computationTime = 0.0
    let startTime = Date()
    
    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }
    
    var mlFramesPerSecond: Double {
        return Double(frames) / computationTime
    }
    
    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }
    
    func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        preconditionFailure("This method must be overridden")
    }
    
    func croppedImage(fullCardImage: CGImage, roiRectangle: CGRect) -> CGImage? {
        // add 10% to our ROI rectangle
        let deltaX = roiRectangle.size.width * 0.1
        let deltaY = roiRectangle.size.height * 0.1
        let roiPlusBuffer = CGRect(x: roiRectangle.origin.x - deltaX * 0.5,
                                   y: roiRectangle.origin.y - deltaY * 0.5,
                                   width: roiRectangle.size.width + deltaX,
                                   height: roiRectangle.size.height + deltaY)
        
        // if the expanded roi rectangle is too big, fall back to the tight roi rectangle
        return fullCardImage.cropping(to: roiPlusBuffer) ?? fullCardImage.cropping(to: roiRectangle)
    }
    
    func croppedImageForSsd(fullCardImage: CGImage, roiRectangle: CGRect) -> CGImage? {
        // add 10% to our ROI rectangle
        let centerX = roiRectangle.origin.x + roiRectangle.size.width * 0.5
        let centerY = roiRectangle.origin.y + roiRectangle.size.height * 0.5
        
        let width = (roiRectangle.size.width * 1.1) < roiRectangle.size.width ? (roiRectangle.size.width * 1.1) : roiRectangle.size.width
        let height = 375.0 * width / 600.0
        let x = centerX - width * 0.5
        let y = centerY - height * 0.5
        
        let ssdRoiRectangle = CGRect(x: x, y: y, width: width, height: height)
        
        // if the expanded roi rectangle is too big, fall back to the tight roi rectangle
        return fullCardImage.cropping(to: ssdRoiRectangle) ?? fullCardImage.cropping(to: roiRectangle)
    }
    
    func croppedImageWithFullWidth(fullCardImage: CGImage, roiRectangle: CGRect) -> CGImage? {
        let x = CGFloat(0.0)
        let width = CGFloat(fullCardImage.width)
        let cy = roiRectangle.origin.y + 0.5 * roiRectangle.size.height
        let height = width * 302.0 / 480.0
        let y = cy - 0.5 * height
        
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        return fullCardImage.cropping(to: cropRect)
    }
    
    static func squareCardImage(fullCardImage: CGImage, roiRectangle: CGRect) -> CGImage? {
        let width = CGFloat(fullCardImage.width)
        let height = width
        let centerY = (roiRectangle.maxY + roiRectangle.minY) * 0.5
        let cropRectangle = CGRect(x: 0.0, y: centerY - height * 0.5,
                                   width: width, height: height)
        return fullCardImage.cropping(to: cropRectangle)
    }
}
