//
//  ScanEventsProtocol.swift
//  CardScan
//
//  Created by Sam King on 8/9/19.
//

import Foundation

public protocol ScanEvents {
    mutating func onNumberRecognized(number: String, expiry: Expiry?, cardImage: CGImage, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?)
    mutating func onScanComplete()
}
