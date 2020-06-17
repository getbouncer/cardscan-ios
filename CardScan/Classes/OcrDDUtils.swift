//
//  OcrDDUtils.swift
//  CardScan
//
//  Created by xaen on 6/17/20.
//

import Foundation

struct OcrDDUtils {
    static let offsetQuickRead:Float = 2.0
    static let falsePositiveTolerance:Float = 1.2
    static let minimumCardDigits = 12
    
    static func isQuickRead(allBoxes: DetectedAllOcrBoxes) -> Bool {
        if (allBoxes.allBoxes.isEmpty) || (allBoxes.allBoxes.count != 16) {
            return false
        }
        
        var boxCenters = [Float]()
        var boxHeights = [Float]()
        var aggregateDeviation: Float = 0
        
        for idx in 0..<allBoxes.allBoxes.count {
            boxCenters.append(Float((allBoxes.allBoxes[idx].rect.midY)))
            boxHeights.append(abs(Float(allBoxes.allBoxes[idx].rect.height)))
        }
        
        let medianYCenter = boxCenters.sorted(by: <)[boxCenters.count / 2]
        let medianHeight = boxHeights.sorted(by: <)[boxHeights.count / 2]
        
        for idx in 0..<boxCenters.count {
            aggregateDeviation += abs(medianYCenter - boxCenters[idx])
        }
        
        if (aggregateDeviation > offsetQuickRead * medianHeight)
        {
            return true
        }
        return false
    }
    
    static func processQuickRead(allBoxes: DetectedAllOcrBoxes) -> String? {
        var _cardNumber: String = ""
        let sortedBoxes = allBoxes.allBoxes.sorted(by: {($0.rect.minY / 2 + $0.rect.maxY / 2)
                                                            < ($1.rect.minY / 2 + $1.rect.maxY / 2)})
        
        var groupSlice = sortedBoxes[..<4]
        var firstGroup = Array(groupSlice)
        firstGroup = firstGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
        
        for idx in 0..<firstGroup.count {
            _cardNumber = _cardNumber + String(firstGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[4..<8]
        var secondGroup = Array(groupSlice)
        secondGroup = secondGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
        
        for idx in 0..<secondGroup.count {
            _cardNumber = _cardNumber + String(secondGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[8..<12]
        var thirdGroup = Array(groupSlice)
        thirdGroup = thirdGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
       
        for idx in 0..<thirdGroup.count {
            _cardNumber = _cardNumber + String(thirdGroup[idx].label)
        }
        
        groupSlice = sortedBoxes[12..<16]
        var fourthGroup = Array(groupSlice)
        fourthGroup = fourthGroup.sorted(by: {$0.rect.minX < $1.rect.minX})
      
        for idx in 0..<fourthGroup.count {
            _cardNumber = _cardNumber + String(fourthGroup[idx].label)
        }
        
        if CreditCardUtils.isValidNumber(cardNumber: _cardNumber){
            return _cardNumber
        }
        return nil
    }
    
    static func sortAndRemoveFalsePositives(allBoxes: DetectedAllOcrBoxes) -> String? {
        
        if (allBoxes.allBoxes.isEmpty) || (allBoxes.allBoxes.count < minimumCardDigits) {
            return nil
        }
        
        var leftCordinates = [Float]()
        var topCordinates = [Float]()
        var bottomCordinates = [Float]()
        
        for idx in 0..<allBoxes.allBoxes.count {
            leftCordinates.append(Float(allBoxes.allBoxes[idx].rect.minX))
            topCordinates.append(Float(allBoxes.allBoxes[idx].rect.minY))
            bottomCordinates.append(Float(allBoxes.allBoxes[idx].rect.maxY))
        }
        
        let medianYmin = topCordinates.sorted(by: <)[topCordinates.count / 2]
        let medianYmax = bottomCordinates.sorted(by: <)[bottomCordinates.count / 2]
        
        let medianHeight = abs(medianYmax - medianYmin)
        let medianCenter = (medianYmin + medianYmax) / 2
        
        let sortedLeftCordinates = leftCordinates.enumerated().sorted(by: {$0.element < $1.element})
        let indices = sortedLeftCordinates.map{$0.offset}
        var _cardNumber: String = ""

        indices.forEach { index in
            let box = allBoxes.allBoxes[index]
            let boxCenter = abs(Float(box.rect.maxY) + Float(box.rect.minY)) / 2
            let boxHeight = abs(Float(box.rect.maxY) - Float(box.rect.minY))
            if abs(boxCenter - medianCenter) < medianHeight && boxHeight < falsePositiveTolerance * medianHeight {
                _cardNumber = _cardNumber + String(box.label)
            }
        }
        
        if CreditCardUtils.isValidNumber(cardNumber: _cardNumber){
            return _cardNumber
        }
        
        return nil
    }
    
}
