//
//  ErrorCorrection.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/22/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

class ErrorCorrection {
    
    var firstPan: Date?
    var frames = 0
    var numbers: [String: Int] = [:]
    var expiries: [String: Int] = [:]
    var names: [String: Int] = [:]
    let startTime = Date()
    let errorCorrectionTime = 1.5
    
    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }
    
    init() { }
    
    func add(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        self.frames += 1
        if let pan = prediction.number {
            if self.firstPan == nil {
                self.firstPan = Date()
            }
            self.numbers[pan] = (self.numbers[pan] ?? 0) + 1
        }
        if let expiry = prediction.expiryForDisplay {
            self.expiries[expiry] = (self.expiries[expiry] ?? 0) + 1
        }
        
        for name in prediction.name?.split(separator: "\n").map({String($0)}) ?? [] {
            self.names[name] = (self.names[name] ?? 0) + 1
        }
        
        guard let firstPan = firstPan else { return nil }
        let predictedNumber = self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        guard let number = predictedNumber else { return nil }
        let predictedExpiry = self.expiries.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let predictedName = self.names.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let isFinished = -firstPan.timeIntervalSinceNow >= errorCorrectionTime
        
        return CreditCardOcrResult(mostRecentPrediction: prediction, number: number, expiry: predictedExpiry, name: predictedName, isFinished: isFinished, duration: -startTime.timeIntervalSinceNow, frames: frames)
    }
}
