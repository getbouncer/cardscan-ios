//
//  DenyCameraUITests.swift
//  CardScanSystemTestUITests
//
//  Created by Sam King on 8/29/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import XCTest

class DenyCameraUITests: XCTestCase {

    var app: XCUIApplication?
    var interruptionToken: NSObjectProtocol?
    
    override func setUp() {
        // this will click both the "deny" option camera permissions and the "ok" button
        // that explains that the user denied permission
        self.interruptionToken = addUIInterruptionMonitor(withDescription: "Camera Services") { (alert) -> Bool in
            alert.buttons.element(boundBy: 0).tap()
            return true
        }
        
        continueAfterFailure = false
        self.app = XCUIApplication();
        self.app?.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.interruptionToken.map { removeUIInterruptionMonitor($0) }
    }


    // The way to test this is to run it on a real device with the CardScanSystemTest
    // app uninstalled so it can get the camera permission dialog and test it
    /*
    func testDeny() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        app.buttons["RunTestButton"].tap()
        
        let expectation = XCTestExpectation(description: "wait until main screen shows")
        DispatchQueue.global(qos: .background).async {
            var exists = false
            while !exists {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.sync {
                    exists = app.buttons["RunTestButton"].exists
                }
            }
            expectation.fulfill()
        }
        
        // This tap is to let the app know that it needs to check for a permission dialog
        app.tap()
        wait(for: [expectation], timeout: 60.0)

        // we should be back on the main screen now, click the run test button again
        // and it should kick us back to the main screen
        app.buttons["RunTestButton"].tap()

        let expectation2 = XCTestExpectation(description: "wait main screen shows2")
        DispatchQueue.global(qos: .background).async {
            var exists = false
            while !exists {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.sync {
                    exists = app.buttons["RunTestButton"].exists
                }
            }
            expectation2.fulfill()
        }
        
        app.tap()
        wait(for: [expectation2], timeout: 60.0)
    }
     */

}
