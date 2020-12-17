//
//  SpmXCFrameworkTestTests.swift
//  SpmXCFrameworkTestTests
//
//  Created by Sam King on 12/17/20.
//

import XCTest
@testable import SpmXCFrameworkTest

class SpmXCFrameworkTestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testModels() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(ViewController.copyTest())
    }
}
