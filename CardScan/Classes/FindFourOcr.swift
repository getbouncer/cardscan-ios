import Foundation

/**
 Main OCR logic.
 
 Our OCR system includes three main parts (1) a detection model, (2) a recognition
 model, and (3) algorithms for putting these together to find credit card numbers.
 
 The detection model works by using a convolutional sliding window over the full
 card to detect sequences of four digits. Soon it will detect expiry numbers
 at the same time, but for now it's just digits. The output of this model is a
 set of boxes on the card that correspond to 4 digit combinations centered and
 contained within the box.
 
 The recognition model also uses a sliding window, but just on boxes and it predicts
 the digit that it finds at each location.
 
 The data we feed these models for background is extremely noisy, so these models
 make a lot of mistakes, thus the need for post processing algorithsm. The
 post processing algorithms take the boxes and try to find combinations that are
 likely numbers, combining and filtering out boxes as it goes.
 */
struct FindFourOcr {
    static let recognizeModel = FourRecognize()
    static let detectModel = FindFour()
    let modelString = "findFour"
    var algorithm: String?
    
    // Model parameters
    let kCardWidth = 480
    let kCardHeight = 302
    let kBoxWidth = 80
    let kBoxHeight = 36
    let kDetectionModelRows = 34
    let kDetectionModelCols = 51
    
    // Statistics about the last prediction
    var predictedBoxes: [CGRect] = []
    var cvvBoxes: [CGRect] = []
    var digitsDetected = 0
    var digitsRecognized = 0
    var lastDetectedBoxes: [CGRect] = []
    var expiryBoxes: [CGRect] = []
    var expiry: Expiry?
    
    /**
     Run prediction on blank images to warm up the GPU and ML hardware.
 
     This function is optional, but will make the first prediction much faster.
     Calling it on app startup or a few seconds before you actually need this
     function will help.
     */
    func warmUp() {
        UIGraphicsBeginImageContext(CGSize(width: kCardWidth, height: kCardHeight))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: kCardWidth, height: kCardHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let pixelBuffer = newImage?.pixelBuffer(width: kCardWidth, height: kCardHeight) {
            let _ = try? FindFourOcr.detectModel.prediction(input1: pixelBuffer)
        }
        
        if let pixelBuffer = newImage?.pixelBuffer(width: kBoxWidth, height: kBoxHeight) {
            let _ = try? FindFourOcr.recognizeModel.prediction(input1: pixelBuffer)
        }
    }
    
    mutating func predict(image: UIImage) -> String? {
        let (number, numberBoxes, allBoxes, expiryBoxes, expiry, algorithm) = self.findFourNumber(image: image)
        self.lastDetectedBoxes = allBoxes ?? []
        self.expiry = expiry
        self.algorithm = algorithm
        self.expiryBoxes = expiryBoxes ?? []
        if number != nil {
            self.predictedBoxes = numberBoxes ?? []
        }
        
        return number
    }
    
    func detectBoxes(prediction: FindFourOutput, image: UIImage) -> ([DetectedBox], [DetectedBox]) {
        // convert model prediction to detection boxes
        var boxes: [DetectedBox] = []
        var expiryBoxes: [DetectedBox] = []
        for row in 0..<kDetectionModelRows {
            for col in 0..<kDetectionModelCols {
                if prediction.hasDigits(row: row, col: col) {
                    let confidence = prediction.digitConfidence(row: row, col: col)
                    let candidateRect = DetectedBox(row: row, col: col, confidence: confidence, numRows: kDetectionModelRows, numCols: kDetectionModelCols, boxSize: CGSize(width: kBoxWidth, height: kBoxHeight), cardSize: CGSize(width: kCardWidth, height: kCardHeight), imageSize: image.size)
                    boxes.append(candidateRect)
                } else if prediction.hasExpiry(row: row, col: col) {
                    let confidence = prediction.expiryConfidence(row: row, col: col)
                    let candidateRect = DetectedBox(row: row, col: col, confidence: confidence, numRows: kDetectionModelRows, numCols: kDetectionModelCols, boxSize: CGSize(width: kBoxWidth, height: kBoxHeight), cardSize: CGSize(width: kCardWidth, height: kCardHeight), imageSize: image.size)
                    expiryBoxes.append(candidateRect)
                }
            }
        }
        
        return (boxes, expiryBoxes)
    }
    
    func findFourNumber(image: UIImage) -> (String?, [CGRect]?, [CGRect]?, [CGRect]?, Expiry?, String?) {
        var algorithm: String?
        
        guard let pixelBuffer = image.pixelBuffer(width: kCardWidth, height: kCardHeight) else {
            return (nil, nil, nil, nil, nil, nil)
        }
        
        let modelInput = FindFourInput(input1: pixelBuffer)
        guard let prediction = try? FindFourOcr.detectModel.prediction(input: modelInput) else {
            return (nil, nil, nil, nil, nil, nil)
        }
        guard let cgImage = image.cgImage else {
            return (nil, nil, nil, nil, nil, nil)
        }
        
        let (boxes, expiryBoxes) = self.detectBoxes(prediction: prediction, image: image)
        let postDetectionAlgorithm = PostDetectionAlgorithm(boxes: boxes)
        var recognizeNumbers = RecognizeNumbers(image: cgImage, numRows: kDetectionModelRows,
                                                numCols: kDetectionModelCols)

        var lines = postDetectionAlgorithm.horizontalNumbers()
        var (number, numberBoxes) = recognizeNumbers.number(lines: lines)
        if number == nil {
            let verticalLines = postDetectionAlgorithm.verticalNumbers()
            (number, numberBoxes) = recognizeNumbers.number(lines: verticalLines)
            lines += verticalLines
        } else {
            algorithm = "horizontal"
        }
    
        if number == nil {
            let amexLines = postDetectionAlgorithm.amexNumbers()
            (number, numberBoxes) = recognizeNumbers.amexNumber(lines: amexLines)
            lines += amexLines
            if number != nil {
                algorithm = "amex"
            }
        } else {
            algorithm = "vertical"
        }
        
        // the same box can show up in multiple lines so make sure that
        // the list we return contains only unique rectangles
        let candidateBoxes = lines.reduce([]) { $0 + $1 }.map { $0.rect }
        var allBoxes: [CGRect] = []
        for box in candidateBoxes {
            if !allBoxes.contains(box) {
                allBoxes.append(box)
            }
        }
        
        let candidateExpiry = expiryBoxes.sorted { $0.confidence > $1.confidence }.prefix(1).map { $0.rect }

        let expiry = candidateExpiry.first.flatMap { Expiry.from(image: cgImage, within: $0) }
        
        return (number, numberBoxes, allBoxes, candidateExpiry, expiry, algorithm)
    }
}
