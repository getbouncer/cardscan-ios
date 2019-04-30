//
//  CardScan_ExampleUITests.swift
//  CardScan_ExampleUITests
//
//  Created by Sam King on 4/30/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest

class CardScan_ExampleUITests: XCTestCase {

    var app: XCUIApplication?
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        self.app = XCUIApplication();
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        self.app?.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCustomStrings() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        addUIInterruptionMonitor(withDescription: "Camera Services") { (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        
        app.buttons["ScanCardCustomStrings"].tap()
        
        XCTAssert(app.staticTexts["New Scan Card"].exists)
        XCTAssert(app.buttons["New Skip"].exists)
        XCTAssert(app.buttons["New Back"].exists)
        XCTAssert(app.staticTexts["New Position Card"].exists)
    }

}
