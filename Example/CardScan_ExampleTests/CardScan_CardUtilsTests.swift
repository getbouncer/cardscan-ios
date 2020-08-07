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
    
    func testCardBin() {
        let amexPan34 = "341222233334444"
        let unionPayPan62 = "6211222233334444"
        let discoverPan64 = "6411222233334444"
        let mastercardPan53 = "5311222233334444"
        let visaPan4 = "4111222233334444"
        let jcbPan35 = "3511222233334444"
        let dinersClubPan300 = "30012222333344"
        
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: amexPan34))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: unionPayPan62))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: discoverPan64))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: mastercardPan53))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: visaPan4))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: jcbPan35))
        XCTAssert(CreditCardUtils.isValidBin(cardNumber: dinersClubPan300))
    }
    
    func testCardLength() {
        let visaNumber = "4111222233334444"
        let amexNumber = "341222233334444"
        let dinersClubNumber = "30012222333344"
        
        XCTAssert(CreditCardUtils.isValidLength(cardNumber: visaNumber))
        XCTAssert(CreditCardUtils.isValidLength(cardNumber: amexNumber))
        XCTAssert(CreditCardUtils.isValidLength(cardNumber: dinersClubNumber))
    }
    
    func testCardNumber() {
        let visaNumber = "4242424242424242"
        let unionPayNumber = "6212345678901232"
        let amexNumber = "370000000000002"
        
        XCTAssert(CreditCardUtils.isValidNumber(cardNumber: visaNumber))
        XCTAssert(CreditCardUtils.isValidNumber(cardNumber: unionPayNumber))
        XCTAssert(CreditCardUtils.isValidNumber(cardNumber: amexNumber))
    }
    
    func testCardCVV() {
        let amexCVV = "4444"
        let visaCVV = "123"
        
        XCTAssert(CreditCardUtils.isValidCvv(cvv: amexCVV, network: CardNetwork.AMEX))
        XCTAssert(CreditCardUtils.isValidCvv(cvv: visaCVV, network: CardNetwork.VISA))
    }
    
    func testCardExpDate() {
        let expMonth = "10"
        let validExpYear = "23"
        let invalidExpYear = "19"
        
        XCTAssert(CreditCardUtils.isValidDate(expMonth: expMonth, expYear: validExpYear))
        XCTAssert(!CreditCardUtils.isValidDate(expMonth: expMonth, expYear: invalidExpYear))
    }
    
    func testRegionalCards() {
        XCTAssert(!CreditCardUtils.isValidNumber(cardNumber: "2200000000000061"))
        CreditCardUtils.prefixesRegional = ["2200"]
        XCTAssert(CreditCardUtils.isValidNumber(cardNumber: "2200000000000061"))
        CreditCardUtils.prefixesRegional = []
    }
}
