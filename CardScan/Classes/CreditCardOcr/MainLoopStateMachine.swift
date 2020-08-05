//
//  MainLoopStateMachine.swift
//  CardScan
//
//  Created by Sam King on 8/5/20.
//

import Foundation

public enum MainLoopState {
    case initial
    case ocrOnly
    case cardOnly
    case ocrAndCard
    case finished
}

public protocol MainLoopStateMachine {
    func loopState() -> MainLoopState
    func event(prediction: CreditCardOcrPrediction) -> MainLoopState
}

open class OcrMainLoopStateMachine: MainLoopStateMachine {
    
    var state: MainLoopState = .initial
    var startTimeForCurrentState = Date()
    
    public let errorCorrectionDurationSeconds = 2.0
    
    public func loopState() -> MainLoopState {
        return state
    }
    
    public func event(prediction: CreditCardOcrPrediction) -> MainLoopState {
                
        let currentState = state
        state = transition(prediction: prediction)
        if state != currentState {
            startTimeForCurrentState = Date()
        }
        
        return state
    }
    
    open func transition(prediction: CreditCardOcrPrediction) -> MainLoopState {
        let timeInCurrentStateSeconds = -startTimeForCurrentState.timeIntervalSinceNow
        let frameHasOcr = prediction.number != nil
        
        switch (state, timeInCurrentStateSeconds, frameHasOcr) {
        case (.initial, _, true):
            return .ocrOnly
        case (.ocrOnly, errorCorrectionDurationSeconds..., _):
            return .finished
        default:
            // no state transitions
            return state
        }
    }
}
