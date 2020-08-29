//
//  CardScanDD_OCRTest.swift
//  CardScan_ExampleTests
//
//  Created by xaen on 6/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScanPrivate

class CardScanDD_OCRTests: XCTestCase {

    override func setUp() {
        SSDOcrDetect.ssdOcrResource = "SSDOcr"

        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        let ocrModelc = documentDirectory.appendingPathComponent("SSDOcr.mlmodelc")
        let _ = try? FileManager.default.removeItem(at: ocrModelc)
    }

    override func tearDown() {
        // Let the setup function clean it up
        self.setUp()
    }

    func resizeImage(image: UIImage, imageWidth: Int, imageHeight: Int) -> UIImage? {

        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage

    }

    func testAmex(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let amexImage = resizeImage(image: UIImage(imageLiteralResourceName: "amex"),
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: amexImage!)
        XCTAssert(prediction! == "379267653791028")
    }

    func testQuickRead(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let quickReadImage = resizeImage(image: UIImage(imageLiteralResourceName: "quickread"),
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: quickReadImage!)
        XCTAssert(prediction! == "4147098244785499")
    }

    func testDiscover(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let discoverImage = resizeImage(image: UIImage(imageLiteralResourceName: "discover"),
                                         imageWidth: imageWidth,
                                         imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: discoverImage!)
        XCTAssert(prediction! == "6011000047527001")
    }

    func testMasterCard(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let mastercardImage = resizeImage(image: UIImage(imageLiteralResourceName: "mastercard"),
                                        imageWidth: imageWidth,
                                        imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: mastercardImage!)
        XCTAssert(prediction! == "5287108337148625")
    }

    func testVisa(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let visaImage = resizeImage(image: UIImage(imageLiteralResourceName: "visa"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: visaImage!)
        XCTAssert(prediction! == "4635516434099347")
    }

    func testBackground(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let quickReadImage = resizeImage(image: UIImage(imageLiteralResourceName: "background"),
                                         imageWidth: imageWidth,
                                         imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: quickReadImage!)
        XCTAssert(prediction == nil)
    }

}
