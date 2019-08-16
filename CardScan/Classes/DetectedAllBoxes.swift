//
//  DetectedAllBoxes.swift
//  CardScan
//
//  Created by Zain on 8/15/19.
//

import Foundation

/**
 Data structure used to store all the detected boxes per frame or scan
 
 */

public struct DetectedAllBoxes{
    public internal(set) var allBoxes: [DetectedSSDBox]
    
    init(){
        allBoxes = [DetectedSSDBox]()
    }
    
    public func toArray() -> [[String: Any]]{
        let frameArray = self.allBoxes.map{$0.toDict()}
        return frameArray
    }
}
