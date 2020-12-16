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
    
    func testForResource() {
        let ssdOcrUrl = CSBundle.compiledModel(forResource: "SSDOcr", withExtension: "mlmodelc")
        XCTAssert(ssdOcrUrl != nil)
    }
}
