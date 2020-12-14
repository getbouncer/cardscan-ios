//
//  CardScanDD_BackgroundTests.swift
//  CardScan_ExampleTests
//
//  Created by xaen on 6/21/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScanDD_BackgroundTests: XCTestCase {

    func resizeImage(image: UIImage, imageWidth: Int, imageHeight: Int) -> UIImage? {

        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage

    }

    func testBackgroundTextDigits(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let backgroundImage = resizeImage(image: UIImage(imageLiteralResourceName: "backgroundTextDigits"),
                                         imageWidth: imageWidth,
                                         imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: backgroundImage!)
        XCTAssert(prediction == nil)
    }

    func testBackgroundScreen(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let backgroundImage = resizeImage(image: UIImage(imageLiteralResourceName: "backgroundScreen"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: backgroundImage!)
        XCTAssert(prediction == nil)
    }

    func testBackgroundDesk(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let backgroundImage = resizeImage(image: UIImage(imageLiteralResourceName: "backgroundDesk"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: backgroundImage!)
        XCTAssert(prediction == nil)
    }

    func testBackgroundWindown(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let backgroundImage = resizeImage(image: UIImage(imageLiteralResourceName: "backgroundWindow"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: backgroundImage!)
        XCTAssert(prediction == nil)
    }

    func testBackgroundSpaceGray(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let backgroundImage = resizeImage(image: UIImage(imageLiteralResourceName: "backgroundSpaceGray"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: backgroundImage!)
        XCTAssert(prediction == nil)
    }

}
