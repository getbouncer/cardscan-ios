//
//  CardScanDD_OCRTest.swift
//  CardScan_ExampleTests
//
//  Created by xaen on 6/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScanDD_OCRTests: XCTestCase {
    struct SyntheticCardImage {
        static func getCardImage(brand: String) -> UIImage {
            let cardImage = UIImage(named: "synthetic_card_\(brand)") ?? UIImage()
            assert(cardImage.size != .zero, "Failed to find an image named synthetic_card_\(brand)")
            return cardImage
        }
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

        let amexImage = resizeImage(image: SyntheticCardImage.getCardImage(brand: "amex"),
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: amexImage!)
        XCTAssert(prediction! == "378282246310005")
    }

    func testQuickRead(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let quickReadImage = resizeImage(image: SyntheticCardImage.getCardImage(brand: "quickread"),
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: quickReadImage!)
        XCTAssert(prediction! == "4242424242424242")
    }

    func testDiscover(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let discoverImage = resizeImage(image: SyntheticCardImage.getCardImage(brand: "discover"),
                                         imageWidth: imageWidth,
                                         imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: discoverImage!)
        XCTAssert(prediction! == "6542635523486624")
    }

    func testMasterCard(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let mastercardImage = resizeImage(image: SyntheticCardImage.getCardImage(brand: "mastercard"),
                                        imageWidth: imageWidth,
                                        imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: mastercardImage!)
        XCTAssert(prediction! == "2717095443231055")
    }

    func testVisa(){
        var ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()

        let imageWidth = ssdOcr.ssdOcrImageWidth
        let imageHeight = ssdOcr.ssdOcrImageHeight

        let visaImage = resizeImage(image: SyntheticCardImage.getCardImage(brand: "visa"),
                                          imageWidth: imageWidth,
                                          imageHeight: imageHeight)

        let prediction = ssdOcr.predict(image: visaImage!)
        XCTAssert(prediction! == "4293656747966064")
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
