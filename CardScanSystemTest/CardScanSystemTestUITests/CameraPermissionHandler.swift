//
//  CameraPermissionHandler.swift
//  CardScanSystemTestUITests
//
//  Created by Jaime Park on 10/29/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import XCTest

class CameraPermissionHandler: XCTestCase {
    func pressSpringboardOkButton() {
        let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboardApp.alerts.buttons["OK"].exists {
            springboardApp.alerts.buttons["OK"].tap()
        }
    }
    
    func pressAllowCameraPermissionsVC(app: XCUIApplication?) {
        guard let app = app else {
            XCTAssert(false)
            return
        }
        
        let authorizedExpectation = XCTestExpectation(description: "Wait until camera permission is granted")
        let closeViewControllerExpectation = XCTestExpectation(description: "Closes VC")
        
        app.buttons["AcceptCameraPermissionsButton"].tap()
        app.tap()
        
        var exists = false
        while !exists {
            pressSpringboardOkButton()
            exists = app.staticTexts["Authorized"].exists
        }
            
        authorizedExpectation.fulfill()
        
        if app.buttons["CloseButton"].exists {
            app.buttons["CloseButton"].tap()
            closeViewControllerExpectation.fulfill()
        }
    
        wait(for: [authorizedExpectation, closeViewControllerExpectation], timeout: 10.0)
    }
}
