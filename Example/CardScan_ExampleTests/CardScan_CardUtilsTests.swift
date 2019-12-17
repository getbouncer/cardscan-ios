//
//  CardScan_CardUtilsTests.swift
//  CardScan_ExampleTests
//
//  Created by Jaime Park on 12/16/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CardScan

class CardScan_CardUtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBin() {
        let amexPanInvalidLength = "1111222233334444"
        let dinersClubInvalidLength = "1111222233334444"
        
        let amexPan34 = "341222233334444"
        let unionPayPan62 = "6211222233334444"
        let discoverPan64 = "6411222233334444"
        let mastercardPan53 = "5311222233334444"
        let visaPan4 = "4111222233334444"
        let jcbPan35 = "3511222233334444"
        let dinersClubPan300 = "30012222333344"
        
        XCTAssert(!CreditCardUtils.isAmex(number: amexPanInvalidLength))
        XCTAssert(!CreditCardUtils.isDinersClub(number: dinersClubInvalidLength))
        XCTAssert(CreditCardUtils.isValidBin(number: amexPan34))
        XCTAssert(CreditCardUtils.isValidBin(number: unionPayPan62))
        XCTAssert(CreditCardUtils.isValidBin(number: discoverPan64))
        XCTAssert(CreditCardUtils.isValidBin(number: mastercardPan53))
        XCTAssert(CreditCardUtils.isValidBin(number: visaPan4))
        XCTAssert(CreditCardUtils.isValidBin(number: jcbPan35))
        XCTAssert(CreditCardUtils.isValidBin(number: dinersClubPan300))
    }
}
