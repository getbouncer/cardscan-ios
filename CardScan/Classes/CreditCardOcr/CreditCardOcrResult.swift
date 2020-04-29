//
//  CreditCardOcrResult.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

struct CreditCardOcrResult {
    let mostRecentPrediction: CreditCardOcrPrediction
    let number: String
    let expiry: String?
    let name: String?
    let isFinished: Bool
    let duration: Double
    let frames: Int
    var framePerSecond: Double {
        return Double(frames) / duration
    }
    var expiryMonth: String? {
        return expiry.flatMap { $0.split(separator: "/").first.map { String($0) }}
    }
    var expiryYear: String? {
        return expiry.flatMap { $0.split(separator: "/").last.map { String($0) }}
    }
}
