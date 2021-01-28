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
    case ocrForceFlash
    case finished
}

public protocol MainLoopStateMachine {
    func loopState() -> MainLoopState
    func event(prediction: CreditCardOcrPrediction) -> MainLoopState
    func reset() -> MainLoopStateMachine
}

// Note: This class is _not_ thread safe, it relies on syncrhonization
// from the `OcrMainLoop`
@objc open class OcrMainLoopStateMachine: NSObject, MainLoopStateMachine {
    public var state: MainLoopState = .initial
    public var startTimeForCurrentState = Date()
    public var hasExpiryPrediction = ScanConfiguration.scanPerformancePriority == .fastScan
    
    let minimumErrorCorrection = 2.0
    let maximumErrorCorrection = ScanConfiguration.scanPerformancePriority == .fastScan ? 2.0 : 4.0
    
    public override init() {}
    
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
        hasExpiryPrediction = hasExpiryPrediction || prediction.expiryForDisplay != nil

        switch (state, timeInCurrentStateSeconds, frameHasOcr, hasExpiryPrediction) {
        case (.initial, _, true, _):
            return .ocrOnly
        case (.ocrOnly, minimumErrorCorrection..., _, true):
            return .finished
        case (.ocrOnly, maximumErrorCorrection..., _, false):
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
