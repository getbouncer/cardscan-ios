import Foundation

/**
 
 Simple utility extensions for making the detection and recognition model outputs
 a little easier to work with.
 
 */

// For the detection output, know if we have digits and our confidence
extension FindFourOutput {
    func hasDigits(row: Int, col: Int) -> Bool {
        return digitConfidence(row: row, col: col) >= 0.5
    }
    
    func hasExpiry(row: Int, col: Int) -> Bool {
        return expiryConfidence(row: row, col: col) >= 0.5
    }

    func expiryConfidence(row: Int, col: Int) -> Double {
        let index: [NSNumber] = [NSNumber(value: 2), NSNumber(value: row), NSNumber(value: col)]
        return self.output1[index].doubleValue
    }
    
    func digitConfidence(row: Int, col: Int) -> Double {
        let index: [NSNumber] = [NSNumber(value: 1), NSNumber(value: row), NSNumber(value: col)]
        return self.output1[index].doubleValue
    }
}

// traditional argmax and confidence for recognition classifier
extension FourRecognizeOutput {
    func argMax(row: Int, col: Int) -> Int {
        return self.argAndValueMax(row: row, col: col).0
    }
    
    func argAndValueMax(row: Int, col: Int) -> (Int, Double) {
        var maxIdx = -1
        var maxValue = NSNumber(value: -1.0)
        for idx in 0..<11 {
            let index: [NSNumber] = [NSNumber(value: idx), NSNumber(value: row), NSNumber(value: col)]
            let value = self.output1[index]
            if value.doubleValue > maxValue.doubleValue {
                maxIdx = idx
                maxValue = value
            }
        }
        
        return (maxIdx, maxValue.doubleValue)
    }
    
    func valueMax(row: Int, col: Int) -> Double {
        return self.argAndValueMax(row: row, col: col).1
    }
}
