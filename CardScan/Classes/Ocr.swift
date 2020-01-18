import Foundation

public class Ocr {
    public var scanStats = ScanStats()
    public var expiry: Expiry?
    
    public var errorCorrectionDuration = 1.0
    var scanEventsDelegate: ScanEvents?
    
    public init() {}
    
    static func configure() {
        if #available(iOS 11.2, *) {
            let ocr = FindFourOcr()
            ocr.warmUp()
        }
    }
    
    var firstResult: Date?
    var numbers: [String: Int] = [:]
    var expiries: [Expiry: Int] = [:]
    
    func updateStats(model: String, boxes: [CGRect], image: CGImage, number: String, cvvBoxes: [CGRect]) {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "0000"
        self.scanStats.model = "\(model).\(build)"
        self.scanStats.success = true
        self.scanStats.endTime = Date()
        
        let predictionResult = PredictionResult(cardWidth: CGFloat(image.width),
                                                cardHeight: CGFloat(image.height),
                                                numberBoxes: boxes,
                                                number: number,
                                                cvvBoxes: cvvBoxes)
        self.scanStats.bin = predictionResult.bin()
        
        let xMin = boxes.map { $0.minX }.min() ?? 0
        let xMax = boxes.map { $0.maxX }.max() ?? 0
        let yMin = boxes.map { $0.minY }.min() ?? 0
        let yMax = boxes.map { $0.maxY }.max() ?? 0
        
        self.scanStats.numberRect = CGRect(x: xMin, y: yMin,
                                           width: xMax - xMin, height: yMax - yMin)
    }
    
    // used just for testing
    @available(iOS 11.2, *)
    public static func updateDetectionModel(resourceName: String) {
        FindFourOcr.detectModel = nil
        FindFourOcr.findFourResource = resourceName
    }
    @available(iOS 11.2, *)
    public static func updateRecognitionModel(resourceName: String) {
        FindFourOcr.recognizeModel = nil
        FindFourOcr.fourRecognizeResource = resourceName
    }
    
    public func userCancelled() {
        self.scanStats.success = false
        self.scanStats.endTime = Date()
    }
    
    @available(iOS 11.2, *)
    public func performWithErrorCorrection(for croppedCardImage: CGImage, squareCardImage: CGImage, fullCardImage: CGImage, predictedNumberPredicate: (String?, String) -> Bool ) -> (String?, Expiry?, Bool, Bool) {
        let number = self.perform(croppedCardImage: croppedCardImage, squareCardImage: squareCardImage, fullCardImage: fullCardImage, predictedNumberPredicate: predictedNumberPredicate)

        if self.firstResult == nil && number != nil {
            self.firstResult = Date()
        }
        
        if let number = number {
            self.numbers[number] = (self.numbers[number] ?? 0) + 1
        }
        
        if let expiry = self.expiry {
            self.expiries[expiry] = (self.expiries[expiry] ?? 0) + 1
        }
        
        let interval = -(self.firstResult ?? Date()).timeIntervalSinceNow
        
        let numberResult = self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let expiryResult = self.expiries.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let done = interval >= self.errorCorrectionDuration
        let foundNumberInThisScan = number != nil
        
        if interval >= (self.errorCorrectionDuration / 2.0) {
            return (numberResult, expiryResult, done, foundNumberInThisScan)
        } else {
            return (numberResult, nil, done, foundNumberInThisScan)
        }
    }
    
    @available(iOS 11.2, *)
    public func perform(croppedCardImage: CGImage, squareCardImage: CGImage?, fullCardImage: CGImage?, predictedNumberPredicate: (String? , String) -> Bool ) -> String? {
        var findFour = FindFourOcr()
        var number = findFour.predict(image: UIImage(cgImage: croppedCardImage))
        
        if let currentNumber = number {
            let errorCorrectedNumber = self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
            if !predictedNumberPredicate(errorCorrectedNumber, currentNumber) {
                number = nil
            }
        }
        
        self.expiry = findFour.expiry
        
        self.scanStats.scans += 1
        self.scanStats.lastFlatBoxes = findFour.lastDetectedBoxes
        self.scanStats.expiryBoxes = findFour.expiryBoxes
        
        if findFour.cardDetected ?? false {
            self.scanStats.cardsDetected += 1
        }
        
        if let number = number {
            // Note: the onScanComplete method is called in ScanBaseViewController
            let xmin = findFour.predictedBoxes.map { $0.minX }.min() ?? 0.0
            let xmax = findFour.predictedBoxes.map { $0.maxX }.max() ?? 0.0
            let ymin = findFour.predictedBoxes.map { $0.minY }.min() ?? 0.0
            let ymax = findFour.predictedBoxes.map { $0.maxY }.max() ?? 0.0
            let numberBoundingBox = CGRect(x: xmin, y: ymin, width: (xmax - xmin), height: (ymax - ymin))
            
            if let squareCardImage = squareCardImage, let fullCardImage = fullCardImage {
                let croppedCardSize = CGSize(width: croppedCardImage.width, height: croppedCardImage.height)
                self.scanEventsDelegate?.onNumberRecognized(number: number, expiry: findFour.expiry, numberBoundingBox: numberBoundingBox, expiryBoundingBox: findFour.expiryBoxes.first, croppedCardSize: croppedCardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
            }
            
            self.scanStats.algorithm = findFour.algorithm
            self.updateStats(model: findFour.modelString, boxes: findFour.predictedBoxes, image: croppedCardImage, number: number, cvvBoxes: findFour.cvvBoxes)
            return number
        }

        return nil
    }
    
    @available(iOS 11.2, *)
    public func perform(for rawImage: CGImage, predicate: (String?, String) -> Bool) -> String? {
        return self.perform(croppedCardImage: rawImage, squareCardImage: nil, fullCardImage: nil, predictedNumberPredicate: predicate)
    }
}
