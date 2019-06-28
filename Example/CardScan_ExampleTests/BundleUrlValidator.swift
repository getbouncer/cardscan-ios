//
//  BundleUrlValidator.swift
//  CardScan_ExampleTests
//
//  Created by Jaime Park on 6/28/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class BundleUrlValidator: XCTestCase {

    override func setUp() {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        
        let detectModelc = documentDirectory.appendingPathComponent("FindFour.mlmodelc")
        
        let _ = try? FileManager.default.removeItem(at: detectModelc)
    }

    override func tearDown() {
        setUp()
    }

    func testForResource() {
        var findFourURl = BundleURL.compiledModel(forResource: "feefifofum", withExtension: "bin", modelName: "FindFour.mlmodelc")
        XCTAssert(findFourURl == nil)
        
        findFourURl = BundleURL.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        XCTAssert(findFourURl != nil)
    }

    func testWithExtension() {
        var findFourURl = BundleURL.compiledModel(forResource: "FindFour", withExtension: "fee", modelName: "FindFour.mlmodelc")
        XCTAssert(findFourURl == nil)
        
        findFourURl = BundleURL.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        XCTAssert(findFourURl != nil)
    }
    
    func testModelName() {
        var findFourURl = BundleURL.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "feefifofum")
        XCTAssert(findFourURl != nil)
        
        findFourURl = BundleURL.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        XCTAssert(findFourURl != nil)
    }
    
    
    

}
