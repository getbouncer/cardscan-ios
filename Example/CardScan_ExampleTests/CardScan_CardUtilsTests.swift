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
    
    func testAmexBin() {
        let amexPan34 = "341222233334444"
        let amexPan37 = "371222233334444"
        let amexPanInvalidLength = "3411222233334444"
        let amexPanInvalidBin = "321222233334444"
        
        XCTAssert(CreditCardUtils.isAmex(number: amexPan34))
        XCTAssert(CreditCardUtils.isAmex(number: amexPan37))
        XCTAssert(!CreditCardUtils.isAmex(number: amexPanInvalidLength))
        XCTAssert(!CreditCardUtils.isAmex(number: amexPanInvalidBin))
    }
    
    func testUnionPayBin() {
        let unionPayPan62 = "6211222233334444"
        let unionPayInvalidLength = "621222233334444"
        let unionPayInvalidBin = "6311222233334444"
        
        XCTAssert(CreditCardUtils.isUnionPay(number: unionPayPan62))
        XCTAssert(!CreditCardUtils.isUnionPay(number: unionPayInvalidLength))
        XCTAssert(!CreditCardUtils.isUnionPay(number: unionPayInvalidBin))
    }
    
    func testDiscoverBin() {
        let discoverPan64 = "6411222233334444"
        let discoverPan65 = "6511222233334444"
        let discoverPan6011 = "6011222233334444"
        let discoverPanInvalidLength = "641222233334444"
        let discoverPanInvalidBin = "6611222233334444"
        
        XCTAssert(CreditCardUtils.isDiscover(number: discoverPan64))
        XCTAssert(CreditCardUtils.isDiscover(number: discoverPan65))
        XCTAssert(CreditCardUtils.isDiscover(number: discoverPan6011))
        XCTAssert(!CreditCardUtils.isDiscover(number: discoverPanInvalidLength))
        XCTAssert(!CreditCardUtils.isDiscover(number: discoverPanInvalidBin))
    }
    
    func testMastercardBin() {
        let mastercardPan53 = "5311222233334444"
        let mastercardPan2222 = "2222222233334444"
        let mastercardPanInvalidLength = "531222233334444"
        let mastercardPanInvalidBin = "2721222233334444"
        
        XCTAssert(CreditCardUtils.isMastercard(number: mastercardPan53))
        XCTAssert(CreditCardUtils.isMastercard(number: mastercardPan2222))
        XCTAssert(!CreditCardUtils.isMastercard(number: mastercardPanInvalidLength))
        XCTAssert(!CreditCardUtils.isMastercard(number: mastercardPanInvalidBin))
    }
    
    func testVisaBin() {
        let visaPan4 = "4111222233334444"
        let visaPanInvalidLength = "411222233334444"
        let visaPanInvalidBin = "5111222233334444"
        
        XCTAssert(CreditCardUtils.isVisa(number: visaPan4))
        XCTAssert(!CreditCardUtils.isVisa(number: visaPanInvalidLength))
        XCTAssert(!CreditCardUtils.isVisa(number: visaPanInvalidBin))
    }
}
