//
//  DetectedAllBoxes.swift
//  CardScan
//
//  Created by Zain on 8/15/19.
//
/**
 Data structure used to store all the detected boxes per frame or scan
 
 */

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
public struct DetectedAllBoxes {
    var allBoxes: [DetectedSSDBox] = []
    
    public init() {}
    
    public func toArray() -> [[String: Any]]{
        let frameArray = self.allBoxes.map{$0.toDict()}
        return frameArray
    }
}

