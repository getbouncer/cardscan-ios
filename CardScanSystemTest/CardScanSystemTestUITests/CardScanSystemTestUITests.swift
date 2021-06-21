//
//  CardScanSystemTestUITests.swift
//  CardScanSystemTestUITests
//
//  Created by Sam King on 7/3/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import XCTest
import AVFoundation

class CardScanSystemTestUITests: XCTestCase {
    let cameraPermissionHandler = CameraPermissionHandler()
    var app: XCUIApplication?
    var interruptionToken: NSObjectProtocol?
    
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    override func setUp() {
        self.interruptionToken = addUIInterruptionMonitor(withDescription: "Camera Services") { (alert) -> Bool in

            let okButton = alert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }

            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
            }
            return true
        }
        
        
        continueAfterFailure = false
        self.app = XCUIApplication();
        self.app?.launch()
        
        cameraPermissionHandler.pressAllowCameraPermissionsVC(app: self.app)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.interruptionToken.map { removeUIInterruptionMonitor($0) }
    }
    
    func testBasicRun() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        app.buttons["RunTestButton"].tap()
        
        let expectation = XCTestExpectation(description: "wait until cc number shows up")
        DispatchQueue.global(qos: .background).async {
            var exists = false
            while !exists {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.sync {
                    exists = app.staticTexts["6297324512093652"].exists
                }
            }
            expectation.fulfill()
        }
        
        // This tap is to let the app know that it needs to check for a permission dialog
        app.tap()
        
        wait(for: [expectation], timeout: 60.0)
        
        let apiToPost = XCTestExpectation(description: "wait api result posts")
        DispatchQueue.global(qos: .background).async {
            var exists = false
            while !exists {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.sync {
                    exists = app.staticTexts["API result posted"].exists
                }
            }
            apiToPost.fulfill()
        }
        
        wait(for: [apiToPost], timeout: 60.0)
    }
    
    func testTorchButton() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        let cardScan = app.buttons["OpenCardScan"]
        let back = app.buttons["Back"]
        let torch = app.buttons["TorchButton"]
        
        cardScan.tap()
        app.tap()
        XCTAssert(torch.exists)
        
        torch.tap()
        torch.tap()
        XCTAssert(back.exists)
        
        back.tap()
    }
    
    func testBackButton() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        app.buttons["SimpleStartButton"].tap()
        app.tap()
        app.buttons["Back"].tap()
        XCTAssert(app.buttons["SimpleStartButton"].exists)
        
        app.buttons["SimpleStartButton"].tap();
        app.buttons["Enter card manually"].tap()
        XCTAssert(app.buttons["SimpleStartButton"].exists)
    }
    
    func testCustomStrings() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        app.buttons["CustomStringsButton"].tap()
        
        XCTAssert(app.staticTexts["New Scan Card"].exists)
        XCTAssert(app.buttons["New Skip"].exists)
        XCTAssert(app.buttons["New Back"].exists)
        XCTAssert(app.staticTexts["New Position Card"].exists)
    }
    
    func testCameraState() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        guard !isSimulator() else {
            print("skipping test when running on a simulator")
            return
        }
        
        let imagePicker = app.buttons["OpenImagePicker"]
        let cancel = app.buttons["Cancel"]
        let cardScan = app.buttons["OpenCardScan"]
        let back = app.buttons["Back"]
        
        
        for _ in 1...3 {
            XCTAssert(imagePicker.exists)
            imagePicker.tap()
            app.tap()
            
            XCTAssert(cancel.exists)
            cancel.tap()
        }
        
        for _ in 1...3 {
            XCTAssert(cardScan.exists)
            cardScan.tap()
            app.tap()
            
            XCTAssert(back.exists)
            back.tap()
        }
    }
    
    func testTorchState() {
        guard let app = self.app else {
            XCTAssert(false);
            return
        }
        
        guard !isSimulator() else {
            print("skipping test when running on a simulator")
            return
        }
        
        let torchCardScanButton = app.buttons["OpenTorchCheckCardScan"]
        let torchButton = app.buttons["TorchButton"]
        let backButton = app.buttons["BackButton"]
        
        XCTAssert(torchCardScanButton.exists)
        torchCardScanButton.tap()
        app.tap()
        
        XCTAssert(torchButton.exists)
        XCTAssert(torchButton.label == "Turn On")
        torchButton.tap()
        
        XCTAssert(torchButton.label == "Turn Off")
        torchButton.tap()
        
        XCTAssert(torchButton.label == "Turn On")
        XCTAssert(backButton.exists)
        backButton.tap()
    }
}
