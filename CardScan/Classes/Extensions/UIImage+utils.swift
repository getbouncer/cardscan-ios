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
