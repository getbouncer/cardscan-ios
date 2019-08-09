public protocol ScanEvents {
    mutating func onNumberRecognized(number: String, expiry: Expiry?, cardImage: CGImage, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?)
    mutating func onScanComplete(scanStats: ScanStats)
}
