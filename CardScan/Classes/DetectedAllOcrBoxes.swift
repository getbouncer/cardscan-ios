//
//  DetectedAllOcrBoxes.swift
//  CardScan
//
//  Created by xaen on 3/22/20.
//

import Foundation
public struct DetectedAllOcrBoxes {
    var allBoxes: [DetectedSSDOcrBox] = []
    
    public init() {}
    
    public func toArray() -> [[String: Any]]{
        let frameArray = self.allBoxes.map{$0.toDict()}
        return frameArray
    }
}
