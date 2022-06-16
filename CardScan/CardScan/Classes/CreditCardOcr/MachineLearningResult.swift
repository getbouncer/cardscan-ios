//
//  MachineLearningResult.swift
//  CardScan
//
//  Created by Sam King on 4/30/20.
//

import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
public class MachineLearningResult {
    let duration: Double
    let frames: Int
    var framePerSecond: Double {
        return Double(frames) / duration
    }
    
    init(duration: Double, frames: Int) {
        self.duration = duration
        self.frames = frames
    }
}
