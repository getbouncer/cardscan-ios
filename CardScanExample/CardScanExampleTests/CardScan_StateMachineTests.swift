//
//  CardScan_StateMachineTests.swift
//  CardScanExampleTests
//
//  Created by Jaime Park on 2/3/21.
//

import XCTest
@testable import CardScan

class CardScan_StateMachineTests: XCTestCase {
    let cardImage: CGImage? = UIImage(imageLiteralResourceName: "synthetic_card_visa").cgImage
    let number = "4673851385043538"
    let expiryMonth = "02"
    let expiryYear = "37"
    
    func testDuration_Initial() {
        guard let cardImage = cardImage else {
            XCTFail("Initial: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrAccurateMainLoopStateMachine()
        XCTAssert(durationStateMachine.state == .initial)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, ocrCroppingRectangle: CGRect(), number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        XCTAssert(state == .ocrOnly)
    }
    
    func testDuration_MinimumErrorCorrection() {
        guard let cardImage = cardImage else {
            XCTFail("Min Duration: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrAccurateMainLoopStateMachine()
        let minDuration = -durationStateMachine.minimumErrorCorrection
        durationStateMachine.state = .ocrOnly
        durationStateMachine.startTimeForCurrentState = Date(timeInterval: minDuration, since: durationStateMachine.startTimeForCurrentState)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, ocrCroppingRectangle: CGRect(), number: number, expiryMonth: expiryMonth, expiryYear: expiryYear, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        
        XCTAssert(state == .finished)
    }
    
    func testDuration_MaximumErrorCorrection() {
        guard let cardImage = cardImage else {
            XCTFail("Max Duration: Tester card image is not available")
            return
        }
        
        let durationStateMachine = OcrAccurateMainLoopStateMachine()
        let maxDuration = -durationStateMachine.maximumErrorCorrection
        
        durationStateMachine.state = .ocrOnly
        durationStateMachine.startTimeForCurrentState = Date(timeInterval: maxDuration, since: durationStateMachine.startTimeForCurrentState)
        
        let prediction = CreditCardOcrPrediction(image: cardImage, ocrCroppingRectangle: CGRect(), number: number, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
        let state = durationStateMachine.event(prediction: prediction)
        
        XCTAssert(state == .finished)
    }
}
