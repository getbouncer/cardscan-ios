//
//  CardScan_ModelDownloadConfigTests.swift
//  CardScan_ExampleTests
//
//  Created by Jaime Park on 7/29/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScan_ModelDownloadConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testModelConfigDownload() {
        let expectation = XCTestExpectation()
        Api.apiKey = "<Put in proper api key>"
        Api.getModelDownloadConfig(endpoint: "/v1/model/ios/bob/1", parameters: [:]) { response, error in
            guard let _ = response, error == nil else {
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testUrlWithQueryParams() {
        guard let urlNoParam = Api.urlWithQueryParameters(baseUrl: "https://api.getbouncer.com", endpoint: "/test", parameters: [:]),
            let urlParam = Api.urlWithQueryParameters(baseUrl: "https://api.getbouncer.com", endpoint: "/test", parameters: ["1":"a"]),
            let urlPlusParam = Api.urlWithQueryParameters(baseUrl: "https://api.getbouncer.com", endpoint: "/test", parameters: ["1":"a+b"])else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(urlNoParam.absoluteString == "https://api.getbouncer.com/test?")
        XCTAssert(urlParam.absoluteString == "https://api.getbouncer.com/test?1=a")
        XCTAssert(urlPlusParam.absoluteString == "https://api.getbouncer.com/test?1=a%2Bb")
    }
}
