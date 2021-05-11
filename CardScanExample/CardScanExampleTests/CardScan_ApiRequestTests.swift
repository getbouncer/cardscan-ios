//
//  CardScan_ApiRequestTests.swift
//  CardScanExampleTests
//
//  Created by Jaime Park on 5/10/21.
//

import XCTest
@testable import CardScan

class CardScan_ApiRequestTests: XCTestCase {
    func testScanStatsRequest() {
        let scanStatistics = ScanStatistics(scans: 0,
                                            cardsDetected: 0,
                                            torchOn: false,
                                            orientation: "Portrait",
                                            success: true,
                                            duration: 0.0,
                                            model: "iPhone11,3",
                                            permissionGranted: true,
                                            userCanceled: false)
        let payload = ScanStatisticsPayload(scanStats: scanStatistics)
        let expectation = XCTestExpectation(description: "Scan Stats Request Expectation")
        
        ScanApi.uploadScanStats(payload: payload, completion: { response, error in
            guard let res = response, error == nil else {
                XCTAssert(false, "Scan Stats Request: Error")
                return
            }
            
            guard res.status == "ok" else {
                XCTAssert(false, "Scan Stats Response: Error")
                return
            }
            
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 10.0)
    }
}
