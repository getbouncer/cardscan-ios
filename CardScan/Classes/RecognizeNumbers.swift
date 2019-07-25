import Foundation

@available(iOS 11.2, *)
struct RecognizeNumbers {
    // parameters for our heuristics
    let maxColDelta = 24
    let errorDxThreshold = 4
    
    let numRows: Int
    let numCols: Int
    var recognizedDigits: [[RecognizedDigits?]]
    var number: String?
    var numberBoxes: [CGRect]?
    let image: CGImage
    
    init(image: CGImage, numRows: Int, numCols: Int) {
        self.numRows = numRows
        self.numCols = numCols
        self.image = image
        
        // we use the cardGrid for the size of this array because we're going to cache
        // the results of the recognition model. We have to make sure that we double
        // check the size of our arrays before accessing these data structures.
        self.recognizedDigits = Array(repeating: Array(repeating: nil, count: numCols), count: numRows)
    }
    
    @available(iOS 11.2, *)
    mutating func number(lines: [[DetectedBox]]) -> (String?, [CGRect]?, Bool) {
        let maxRow = lines.map { $0.map { $0.row }}.flatMap { $0 }.max() ?? 0
        let maxCol = lines.map { $0.map { $0.col }}.flatMap { $0 }.max() ?? 0
        
        var detectedCard = false
        
        if maxRow >= self.numRows || maxCol >= self.numCols {
            print("card grid size mismatch, bailing")
            return (nil, nil, detectedCard)
        }
        
        for line in lines {
            var candidateNumber = ""
            var detectedDigitsCount = 0
            
            for word in line {
                guard let recognized = self.cachedDigits(box: word) else {
                    return (nil, nil, false)
                }
                
                let (number, detectedDigits) = recognized.four()
                candidateNumber += number
                if detectedDigits {
                    detectedDigitsCount += 1
                }
            }
            
            if (detectedDigitsCount >= 4) {
                detectedCard = true
            }
            
            if candidateNumber.count == 16  && CreditCardUtils.luhnCheck(candidateNumber) {
                self.number = candidateNumber
                self.numberBoxes = line.map { $0.rect }
            }
        }
        
        return (self.number, self.numberBoxes, detectedCard)
    }
    
    @available(iOS 11.2, *)
    mutating func cachedDigits(box: DetectedBox) -> RecognizedDigits? {
        var recognizedDigits: RecognizedDigits? = nil
        if self.recognizedDigits[box.row][box.col] == nil {
            recognizedDigits = RecognizedDigits.from(image: self.image, within: box.rect)
            self.recognizedDigits[box.row][box.col] = recognizedDigits
        } else {
            recognizedDigits = self.recognizedDigits[box.row][box.col]
        }
        
        return recognizedDigits
    }
    
    @available(iOS 11.2, *)
    mutating func recognizeAmexDigits(for line: [DetectedBox]) -> (String?, [CGRect]?) {
        
        let recognizedDigits = line.compactMap { self.cachedDigits(box: $0) }
        if recognizedDigits.count != line.count {
            print("couldn't lookup cached digits")
            return (nil, nil)
        }

        let startCol = line.first?.col ?? 0
        let numCols = (line.last?.col ?? 0) + 8 - startCol
        let positionsPerBox = 16
        let numPositions = numCols * 2
        var digits = Array(repeating: 10, count: numPositions)

        for position in 0..<numPositions {
            for (box, recognized) in zip(line, recognizedDigits) {
                let boxPosition = (box.col  - startCol) * 2
                if position >= boxPosition && position < (boxPosition + positionsPerBox) {
                    let digitIdx = position - boxPosition
                    if digits[position] == 10 {
                        digits[position] = recognized.nonMaxSuppression()[digitIdx]
                    }
                }
            }
        }
        
        // if we get two next to each other squash them
        for idx in 0..<(digits.count-1) {
            if digits[idx] == digits[idx+1] {
                digits[idx] = 10
            }
        }
        
        let candidateNumber = digits.filter { $0 != 10 }.map { String($0) }.joined()
        
        if candidateNumber.count == 15  && CreditCardUtils.luhnCheck(candidateNumber) {
            return (candidateNumber, line.map { $0.rect })
        }
        
        return (nil, nil)
    }
    
    @available(iOS 11.2, *)
    mutating func amexNumber(lines: [[DetectedBox]]) -> (String?, [CGRect]?) {
        let maxRow = lines.map { $0.map { $0.row }}.flatMap { $0 }.max() ?? 0
        let maxCol = lines.map { $0.map { $0.col }}.flatMap { $0 }.max() ?? 0
        
        if maxRow >= self.numRows || maxCol >= self.numCols {
            print("card grid size mismatch, bailing")
            return (nil, nil)
        }
        
        for line in lines {
            let (candidateNumber, boxes) = self.recognizeAmexDigits(for: line)
            if candidateNumber != nil {
                self.number = candidateNumber
                self.numberBoxes = boxes
                return (candidateNumber, boxes)
            }
        }
        
        return (nil, nil)
    }
}
