import Foundation

@available(iOS 11.2, *)
struct RecognizedDigits {
    static let kImageWidth = 80
    static let kImageHeight = 36
    static let kNumPredictions = 17
    static let kBackgroundClass = 10
    static let kDigitMinConfidence = 0.15
    
    let digits: [Int]
    let confidence: [Double]
    
    static func from(image: CGImage, within box: CGRect, minConfidence: Double = kDigitMinConfidence) -> RecognizedDigits? {
        guard let croppedImage = image.cropping(to: box) else {
            return nil
        }
        
        guard let pixelBuffer = UIImage(cgImage: croppedImage).pixelBuffer(width: kImageWidth, height: kImageHeight) else {
            return nil
        }
        
        guard let recognizeModel = FindFourOcr.recognizeModel else {
            print("Models not initialized")
            return nil
        }
        
        let modelInput = FourRecognizeInput(input1: pixelBuffer)
        guard let prediction = try? recognizeModel.prediction(input: modelInput) else {
            return nil
        }
        
        var digits: [Int] = []
        var confidence: [Double] = []
        for col in 0..<kNumPredictions {
            let (arg, value) = prediction.argAndValueMax(row: 0, col: col)
            
            if value < minConfidence {
                digits.append(kBackgroundClass)
            } else {
                digits.append(arg)
            }
            confidence.append(value)
        }
        
        return RecognizedDigits(digits: digits, confidence: confidence)
    }
    
    func nonMaxSuppression() -> [Int] {
        var digits: [Int] = self.digits.map { $0 }
        var confidence: [Double] = self.confidence.map { $0 }
        
        // greedy non max suppression
        for idx in 0..<(RecognizedDigits.kNumPredictions-1) {
            if digits[idx] != RecognizedDigits.kBackgroundClass && digits[idx+1] != RecognizedDigits.kBackgroundClass {
                if confidence[idx] < confidence[idx+1] {
                    digits[idx] = RecognizedDigits.kBackgroundClass
                    confidence[idx] = 1.0
                } else {
                    digits[idx+1] = RecognizedDigits.kBackgroundClass
                    confidence[idx+1] = 1.0
                }
            }
        }
        
        return digits
    }
    
    func toDebugString() -> String {
        let digits = self.nonMaxSuppression().map { $0 == 10 ? "-" : String($0) }.joined()
        return digits
    }
    
    func toString() -> (String, [Int]) {
        let digits = self.nonMaxSuppression()
        return (digits.filter { $0 != RecognizedDigits.kBackgroundClass }.map { String($0) }.joined(), digits)
    }
    
    func four() -> (String, Bool) {
        var (result, digits) = self.toString()
        
        let detectedDigits = result.count > 0
        
        if result.count < 4 {
            return ("", detectedDigits)
        }
        
        // since we know that we have too many digits, trim from the outer most digits. Since we
        // designed our detection model to center digits, this should work
        var fromLeft = true
        var leftIdx = 0
        var rightIdx = digits.count - 1
        while result.count > 4 {
            if fromLeft {
                if digits[leftIdx] != RecognizedDigits.kBackgroundClass {
                    result = String(result.dropFirst())
                    digits[leftIdx] = RecognizedDigits.kBackgroundClass
                }
                fromLeft = false
                leftIdx += 1
            } else {
                if digits[rightIdx] != RecognizedDigits.kBackgroundClass {
                    result = String(result.dropLast())
                    digits[rightIdx] = RecognizedDigits.kBackgroundClass
                }
                fromLeft = true
                rightIdx -= 1
            }
        }
        
        // as a last error check make sure that all of the digits are equally
        // spaced and reject the whole lot if they aren't. This can fix errors
        // on cards with hard to read digits and small fonts where it can sometimes
        // pick up edge digits from another group.
        let positions: [Int] = digits.enumerated().compactMap { t in
            if t.element != RecognizedDigits.kBackgroundClass {
                return t.offset
            } else {
                return nil
            }
        }
        
        let deltas = zip(positions, positions.dropFirst()).map { $0.1 - $0.0 }
        let minDelta = deltas.min() ?? 0
        let maxDelta = deltas.max() ?? 0
        
        if maxDelta > (minDelta+1) {
            return ("", detectedDigits)
        }
        
        return (result, detectedDigits)
    }
    
}
