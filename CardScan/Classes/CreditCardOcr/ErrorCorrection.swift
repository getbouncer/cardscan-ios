import Foundation

open class ErrorCorrection {
    let state: MainLoopStateMachine = OcrMainLoopStateMachine()
    public var frames = 0
    var numbers: [String: Int] = [:]
    var expiries: [String: Int] = [:]
    var names: [String: Int] = [:]
    public let startTime = Date()
    public var mostRecentPrediction: CreditCardOcrPrediction?
    
    
    
    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }
    
    public init() { }
    
    var number: String? {
        return self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
    }
    
    open func result() -> CreditCardOcrResult? {
        guard state.loopState() != .initial else { return nil }
        let predictedNumber = self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        guard let number = predictedNumber else { return nil }
        let predictedExpiry = self.expiries.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let predictedName = self.names.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let isFinished = state.loopState() == .finished
        guard let prediction = self.mostRecentPrediction else { return nil }
        
        return CreditCardOcrResult(mostRecentPrediction: prediction, number: number, expiry: predictedExpiry, name: predictedName, isFinished: isFinished, duration: -startTime.timeIntervalSinceNow, frames: frames)
    }
    
    open func add(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        self.frames += 1
        if let pan = prediction.number {
            self.numbers[pan] = (self.numbers[pan] ?? 0) + 1
        }
        if let expiry = prediction.expiryForDisplay {
            self.expiries[expiry] = (self.expiries[expiry] ?? 0) + 1
        }
        
        for name in prediction.name?.split(separator: "\n").map({String($0)}) ?? [] {
            self.names[name] = (self.names[name] ?? 0) + 1
        }
        
        self.mostRecentPrediction = prediction
        
        let _ = state.event(prediction: prediction)
        
        return result()
    }
    
    open func reset() -> ErrorCorrection {
        return ErrorCorrection()
    }
}
