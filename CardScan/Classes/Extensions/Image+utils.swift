//
//  UIImage+utils.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/22/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import UIKit

extension UIImage {
    static func grayImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        UIColor.gray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImage {
    func drawBoundingBoxesOnImage(boxes: [(UIColor, CGRect)]) -> UIImage? {
        let image = UIImage(cgImage: self)
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint(x: 0,y :0))
        
        UIGraphicsGetCurrentContext()?.setLineWidth(3.0)
        
        for (color, box) in boxes {
            color.setStroke()
            UIRectFrame(box)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
