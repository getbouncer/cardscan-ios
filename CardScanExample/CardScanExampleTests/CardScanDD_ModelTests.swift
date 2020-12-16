//
//  CardScanDD_ModelTests.swift
//  CardScan_ExampleTests
//
//  Created by xaen on 6/19/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScanDD_ModelTests: XCTestCase {

    var origResourceName: String?
    
    override func setUp() {
        origResourceName = SSDOcrDetect.ssdOcrResource
    }
    
    override func tearDown() {
        guard let name = origResourceName else { return }
        SSDOcrDetect.ssdOcrResource = name
    }
    
    func testModelLoading() {
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
        XCTAssert(ssdOcr.ssdOcrModel != nil)
    }

    func testModelLoadingFailure() {
        // first try it with a non existant resource
        SSDOcrDetect.ssdOcrResource = "randomtext"
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
        XCTAssert(ssdOcr.ssdOcrModel == nil)
    }

    func testModelThrowingAndHandlingExceptions() {

        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        // The model expects an image width = 600 and height = 375 and we input the wrong image dimensions
        // to test the models throwing exceptions

        UIGraphicsBeginImageContext(CGSize(width: imageHeight, height: imageWidth))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: imageHeight, height: imageWidth))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let pixelBuffer = newImage.pixelBuffer(width: imageHeight, height: imageWidth)!
        XCTAssertThrowsError(try ssdOcr.ssdOcrModel!.prediction(_0: pixelBuffer)) { error in
            XCTAssert(error.localizedDescription == "Input image feature 0 does not match model description")
        }

        // test whether we can handle exceptions

        let prediction = ssdOcr.predict(image: newImage)
        XCTAssert(prediction == nil)

    }

}
