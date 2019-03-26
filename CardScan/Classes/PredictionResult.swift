//
//  PredictionResult.swift
//  CardScan
//
//  Created by Sam King on 11/16/18.
//

import Foundation

//
// The PredictionResult includes images of the bin and the last four. The OCR model returns clusters of 4 digits for
// the number so we use only the first 4 for the bin and the full last 4 as a single image
//
struct PredictionResult {
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let numberBoxes: [CGRect]
    let number: String
    let cvvBoxes: [CGRect]
    
    func bin() -> String {
        return String(number.prefix(6))
    }
    
    func last4() -> String {
        return String(number.suffix(4))
    }
    
    static func translateBox(from modelSize: CGSize, to imageSize: CGSize, for box: CGRect) -> CGRect {
        let boxes = translateBoxes(from: modelSize, to: imageSize, for: [box])
        return boxes.first!
    }
    
    static func translateBoxes(from modelSize: CGSize, to imageSize: CGSize, for boxes: [CGRect]) -> [CGRect] {
        let scaleX = imageSize.width / modelSize.width
        let scaleY = imageSize.height / modelSize.height
        
        return boxes.map { CGRect(x: $0.origin.x * scaleX, y: $0.origin.y * scaleY, width: $0.size.width * scaleX, height: $0.size.height * scaleY) }
    }
    
    func translateNumber(to originalImage: CGImage) -> [CGRect] {
        let scaleX = CGFloat(originalImage.width) / self.cardWidth
        let scaleY = CGFloat(originalImage.height) / self.cardHeight
        
        return self.numberBoxes.map { CGRect(x: $0.origin.x * scaleX, y: $0.origin.y * scaleY, width: $0.size.width * scaleX, height: $0.size.height * scaleY) }
    }
    
    func extractImagePng(from image: CGImage, for box: CGRect) -> String? {
        let uiImage = image.cropping(to: box).map { UIImage(cgImage: $0) }
        return uiImage.flatMap { $0.pngData()?.base64EncodedString() }
    }
        
    func binImagePng(originalImage: CGImage) -> String? {
        let boxes = translateNumber(to: originalImage)
        guard let box = boxes.prefix(1).first else {
            return nil
        }
        return extractImagePng(from: originalImage, for: box)
    }
    
    func last4ImagePng(originalImage: CGImage) -> String? {
        let boxes = translateNumber(to: originalImage)
        guard let box = boxes.suffix(1).first else {
            return nil
        }
        return extractImagePng(from: originalImage, for: box)
    }
    
    func resizeImage(image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func backgroundImageJpeg(originalImage: CGImage) -> String? {
        guard let resizedImage = self.resizeImage(image: UIImage(cgImage:originalImage), to: CGSize(width: 600, height: 378)) else {
            print("couldn't resize image")
            return nil
        }
        
        guard let cgImage = resizedImage.cgImage else {
            print("no cgImage")
            return nil
        }
        
        let boxes = self.translateNumber(to: cgImage)
        let xmin = boxes.map { $0.minX }.min() ?? 0.0
        let ymin = boxes.map { $0.minY }.min() ?? 0.0
        let xmax = boxes.map { $0.maxX }.max() ?? CGFloat(cgImage.width)
        let ymax = boxes.map { $0.maxY }.max() ?? CGFloat(cgImage.height)
        
        let box = CGRect(x: xmin, y: ymin, width: xmax - xmin, height: ymax - ymin)
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        resizedImage.draw(at: CGPoint(x: 0,y :0))
        UIColor.black.setStroke()
        UIColor.black.setFill()
        
        UIRectFill(box)
    
        let originalImageSize = CGSize(width: originalImage.width, height: originalImage.height)
        for cvvBox in PredictionResult.translateBoxes(from: originalImageSize, to: resizedImage.size, for: self.cvvBoxes) {
            UIRectFill( cvvBox)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage?.cgImage.map { UIImage(cgImage: $0) }?.jpegData(compressionQuality: 0.75)?.base64EncodedString()
    }
}
