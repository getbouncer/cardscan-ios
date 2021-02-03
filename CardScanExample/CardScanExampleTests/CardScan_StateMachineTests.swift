//
//  CardScan_StateMachineTests.swift
//  CardScanExampleTests
//
//  Created by Jaime Park on 2/3/21.
//

import XCTest
@testable import CardScan

class CardScan_StateMachineTests: XCTestCase {
    let cardImage: CGImage? = UIImage(imageLiteralResourceName: "frame0").cgImage
    let number = "4847186095118770"
    let expiryMonth = "03"
    let expiryYear = "21"
    
    func testDuration_Initial() {
        guard let cardImage = cardImage else {
            XCTFail("Initial: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrDurationMainLoopStateMachine()
        XCTAssert(durationStateMachine.state == .initial)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        XCTAssert(state == .ocrOnly)
    }
    
    func testDuration_MinimumErrorCorrection() {
        guard let cardImage = cardImage else {
            XCTFail("Min Duration: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrDurationMainLoopStateMachine()
        let minDuration = -durationStateMachine.minimumErrorCorrection
        durationStateMachine.state = .ocrOnly
        durationStateMachine.startTimeForCurrentState = Date(timeInterval: minDuration, since: durationStateMachine.startTimeForCurrentState)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, number: number, expiryMonth: expiryMonth, expiryYear: expiryYear, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        
        XCTAssert(state == .finished)
    }
    
    func testDuration_MaximumErrorCorrection() {
        guard let cardImage = cardImage else {
            XCTFail("Max Duration: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrDurationMainLoopStateMachine()
        let maxDuration = -durationStateMachine.maximumErrorCorrection
        
        durationStateMachine.state = .ocrOnly
        durationStateMachine.startTimeForCurrentState = Date(timeInterval: maxDuration, since: durationStateMachine.startTimeForCurrentState)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        
        XCTAssert(state == .finished)
    }
}
