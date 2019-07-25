//
//  ScanStats.swift
//  CardScan
//
//  Created by Sam King on 11/13/18.
//

import Foundation

public struct ScanStats {
    var startTime = Date()
    public var scans = 0
    public var flatDigitsRecognized = 0
    public var flatDigitsDetected = 0
    public var embossedDigitsRecognized = 0
    public var embossedDigitsDetected = 0
    public var torchOn = false
    public var success: Bool?
    public var endTime: Date?
    public var model: String?
    public var algorithm: String?
    public var binImagePng: String?
    public var bin: String?
    public var last4ImagePng: String?
    public var last4: String?
    public var backgroundImageJpeg: String?
    public var lastFlatBoxes: [CGRect]?
    public var lastEmbossedBoxes: [CGRect]?
    public var deviceType: String?
    public var numberRect: CGRect?
    public var expiryBoxes: [CGRect]?
    public var cardsDetected = 0
    
    init() {
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceType = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                return
            }
            
            if charDigit == 0 {
                break
            }
            
            deviceType += String(UnicodeScalar(UInt8(charDigit)))
        }
        
        self.deviceType = deviceType
    }
    
    public func toDictionaryForServer() -> [String: Any] {
        return ["scans": self.scans,
                "flat_digits_recognized": self.flatDigitsDetected,
                "flat_digits_detected": self.flatDigitsDetected,
                "embossed_digits_recognized": self.embossedDigitsRecognized,
                "embossed_digits_detected": self.embossedDigitsDetected,
                "torch_on": self.torchOn,
                "success": self.success ?? false,
                "duration": self.duration(),
                "model": self.model ?? "unknown",
                "bin": self.bin ?? "",
                "bin_image_png": self.binImagePng ?? "",
                "last4": self.last4 ?? "",
                "last4_image_png": self.last4ImagePng ?? "",
                "background_image_jpeg": self.backgroundImageJpeg ?? "",
                "device_type": self.deviceType ?? ""]
    }
    
    public func toDictionaryForAnalytics() -> [String: Any] {
        return ["scans": self.scans,
                "cards_detected": self.cardsDetected,
                "torch_on": self.torchOn,
                "success": self.success ?? false,
                "duration": self.duration(),
                "model": self.model ?? "unknown",
                "device_type": self.deviceType ?? ""]
    }
    
    public func toDictionaryForFraudCheck() -> [String: Any] {
        return ["scans": self.scans,
                "torch_on": self.torchOn,
                "success": self.success ?? false,
                "duration": self.duration(),
                "model": self.model ?? "unknown",
                "device_type": self.deviceType ?? ""]
    }
    
    public func duration() -> Double {
        guard let endTime = self.endTime else {
            return 0.0
        }
        
        return endTime.timeIntervalSince(self.startTime)
    }
    
    func image(from base64String: String?) -> UIImage? {
        guard let string = base64String else {
            return nil
        }
        
        return Data(base64Encoded: string).flatMap { UIImage(data: $0) }
    }
    
    // helper functions for debugging
    public func backgroundImage() -> UIImage? {
        return self.image(from: self.backgroundImageJpeg)
    }
    
    public func binImage() -> UIImage? {
        return self.image(from: self.binImagePng)
    }
    
    public func last4Image() -> UIImage? {
        return self.image(from: self.last4ImagePng)
    }
    
    public func imagesSize() -> Int {
        var size = 0
        size += self.backgroundImageJpeg?.count ?? 0
        size += self.last4ImagePng?.count ?? 0
        size += self.binImagePng?.count ?? 0
        
        return size
    }
}
