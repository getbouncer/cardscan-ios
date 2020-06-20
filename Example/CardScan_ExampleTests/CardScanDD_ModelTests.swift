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
    
    override func setUp() {
        SSDOcrDetect.ssdOcrModel = nil
        SSDOcrDetect.ssdOcrResource = "SSDOcr"

        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        
        let ocrModelc = documentDirectory.appendingPathComponent("SSDOcr.mlmodelc")

        let _ = try? FileManager.default.removeItem(at: ocrModelc)
    }

    override func tearDown() {
        // Let the setup function clean it up
        self.setUp()
    }

    func testModelLoading() {
        XCTAssert(SSDOcrDetect.ssdOcrModel == nil)
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
        XCTAssert(SSDOcrDetect.ssdOcrModel != nil)
    }
    
    func testModelLoadingFailure() {
        // first try it with a non existant resource
        SSDOcrDetect.ssdOcrResource = "randomtext"
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
        XCTAssert(SSDOcrDetect.ssdOcrModel == nil)
    }

}
