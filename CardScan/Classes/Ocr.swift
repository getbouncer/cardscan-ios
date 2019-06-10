public class Ocr {
    public var scanStats = ScanStats()
    public var expiry: Expiry?
    
    public var errorCorrectionDuration = 1.0
    
    public init() {}
    
    static func configure() {
        if #available(iOS 11.0, *) {
            if ModelDownloader.download() {
                let ocr = FindFourOcr()
                ocr.warmUp()
            }
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
        self.scanStats.backgroundImageJpeg = predictionResult.backgroundImageJpeg(originalImage: image)
        self.scanStats.bin = predictionResult.bin()
        self.scanStats.binImagePng = predictionResult.binImagePng(originalImage: image)
        self.scanStats.last4 = predictionResult.last4()
        self.scanStats.last4ImagePng = predictionResult.last4ImagePng(originalImage: image)
        
        let xMin = boxes.map { $0.minX }.min() ?? 0
        let xMax = boxes.map { $0.maxX }.max() ?? 0
        let yMin = boxes.map { $0.minY }.min() ?? 0
        let yMax = boxes.map { $0.maxY }.max() ?? 0
        
        self.scanStats.numberRect = CGRect(x: xMin, y: yMin,
                                           width: xMax - xMin, height: yMax - yMin)
    }
    
    public func userCancelled() {
        self.scanStats.success = false
        self.scanStats.endTime = Date()
    }
    
    @available(iOS 11.0, *)
    public func performWithErrorCorrection(for rawImage: CGImage) -> (String?, Expiry?, Bool, Bool) {
        let number = self.perform(for: rawImage)

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
    
    @available(iOS 11.0, *)
    public func perform(for rawImage: CGImage) -> String? {
        var findFour = FindFourOcr()
        let number = findFour.predict(image: UIImage(cgImage: rawImage))
        self.expiry = findFour.expiry
        
        self.scanStats.scans += 1
        self.scanStats.lastFlatBoxes = findFour.lastDetectedBoxes
        self.scanStats.expiryBoxes = findFour.expiryBoxes
        
        if let number = number {
            self.scanStats.algorithm = findFour.algorithm
            self.updateStats(model: findFour.modelString, boxes: findFour.predictedBoxes, image: rawImage, number: number, cvvBoxes: findFour.cvvBoxes)
            return number
        }

        return nil
    }
}
