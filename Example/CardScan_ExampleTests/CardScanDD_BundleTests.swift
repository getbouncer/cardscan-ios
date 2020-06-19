//
//  CardScanDD_BundleTests.swift
//  CardScan_ExampleTests
//
//  Created by xaen on 6/18/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScanDD_BundleTests: XCTestCase {
    override func setUp() {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        
        let detectModelc = documentDirectory.appendingPathComponent("SSDOcr.mlmodelc")
        
        let _ = try? FileManager.default.removeItem(at: detectModelc)
    }
    
    override func tearDown() {
        setUp()
    }
    
    func testForResource() {
        let ssdOcrUrl = CSBundle.compiledModel(forResource: "SSDOcr", withExtension: "mlmodelc")
        XCTAssert(ssdOcrUrl != nil)
    }
    
    func testWithExtension() {
        let ssdOcrUrl = CSBundle.compiledModel(forResource: "SSDOcr", withExtension: "mlmodelc")
        XCTAssert(ssdOcrUrl != nil)
    }
}
