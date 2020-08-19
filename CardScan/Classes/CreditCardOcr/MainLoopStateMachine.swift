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
    case ocrIncorrect
    case ocrDelayForCard
    case finished
}

public protocol MainLoopStateMachine {
    func loopState() -> MainLoopState
    func event(prediction: CreditCardOcrPrediction) -> MainLoopState
    func reset() -> MainLoopStateMachine
}

// Note: This class is _not_ thread safe, it relies on syncrhonization
// from the `OcrMainLoop`
open class OcrMainLoopStateMachine: MainLoopStateMachine {
    public var state: MainLoopState = .initial
    public var startTimeForCurrentState = Date()
    
    public init() { }
    
    public let errorCorrectionDurationSeconds = 2.0
    
    public func loopState() -> MainLoopState {
        return state
    }
    
    public func event(prediction: CreditCardOcrPrediction) -> MainLoopState {
        let newState = transition(prediction: prediction)
        if let newState = newState {
            startTimeForCurrentState = Date()
            state = newState
        }
        
        return newState ?? state
    }
    
    open func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let timeInCurrentStateSeconds = -startTimeForCurrentState.timeIntervalSinceNow
        let frameHasOcr = prediction.number != nil
        
        switch (state, timeInCurrentStateSeconds, frameHasOcr) {
        case (.initial, _, true):
            return .ocrOnly
        case (.ocrOnly, errorCorrectionDurationSeconds..., _):
            return .finished
        default:
            // no state transitions
            return nil
        }
    }
    
    open func reset() -> MainLoopStateMachine {
        return OcrMainLoopStateMachine()
    }
}
