//
//  CardScan_BundleURL_Tests.swift
//  CardScan_ExampleTests
//
//  Created by Jaime Park on 6/27/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScan_BundleURL_Tests: XCTestCase {
    
    override func setUp() {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)

        let detectModelc = documentDirectory.appendingPathComponent("FindFour.mlmodelc")

        let _ = try? FileManager.default.removeItem(at: detectModelc)

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        setUp()
    }

    func testBundleUrl(){
        //test bundle url
        let t = TestBundle()
        let s = TestBundle()
        s.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        
        
        XCTAssert(t.bundleUrl == nil)
        t.setBundleUrl()
        XCTAssert(t.bundleUrl != nil)
        XCTAssert(t.bundleUrl == s.bundleUrl)
    }

    func testBundle(){
        //test bundle
        let t = TestBundle()
        let s = TestBundle()
        s.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        
        
        XCTAssert(t.bundle == nil)
        t.setBundle(url: URL(fileURLWithPath: "googoogaagaa"))
        XCTAssert(t.bundle == nil)
        XCTAssert(s.bundleUrl != nil)
        t.setBundle(url: s.bundleUrl!)
        XCTAssert(t.bundle != nil)
        XCTAssert(t.bundle == s.bundle)
    }
    
    func testModelURL(){
        //test model url
        let t = TestBundle()
        let s = TestBundle()
        s.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        
        XCTAssert(t.modelUrl == nil)
        t.setModelUrl(bundle: Bundle(identifier: "fee"), forResource: "FindFour", withExtension: "bin")
        XCTAssert(t.modelUrl == nil)
        t.setModelUrl(bundle: s.bundle, forResource: "fi", withExtension: "bin")
        XCTAssert(t.modelUrl == nil)
        t.setModelUrl(bundle: s.bundle, forResource: "FindFour", withExtension: "fo")
        XCTAssert(t.modelUrl == nil)
        t.setModelUrl(bundle: s.bundle, forResource: "FindFour", withExtension: "bin")
        XCTAssert(t.modelUrl != nil)
        XCTAssert(t.modelUrl == s.modelUrl)
    }
    
    func testCompiledURL(){
        //test model compile
        let t = TestBundle()
        let s = TestBundle()
        s.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
    
        
        XCTAssertFalse(t.compiled)
        XCTAssert(t.compiledUrl == nil)
        t.testCompiled(url: URL(fileURLWithPath: "googoogaagaa"))
        XCTAssertFalse(t.compiled)
        XCTAssert(s.modelUrl != nil)
        t.testCompiled(url: s.modelUrl!)
        XCTAssert(t.compiledUrl != nil)
        XCTAssertTrue(t.compiled)
    }
    
    func testCompiledModel(){
        let s = TestBundle()
        XCTAssert(s.compiledModel == nil)
        
        s.compiledModel(forResource: "FindFour", withExtension: "bin", modelName: "FindFour.mlmodelc")
        XCTAssert(s.compiledModel != nil)
    }

}
