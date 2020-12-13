//
//  CreditCardOcrPrediction.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import CoreGraphics
import Foundation

public struct UxFrameConfidenceValues {
    public let hasOcr: Bool
    public let uxPan: Double
    public let uxNoPan: Double
    public let uxNoCard: Double
    
    public init(hasOcr: Bool, uxPan: Double, uxNoPan: Double, uxNoCard: Double) {
        self.hasOcr = hasOcr
        self.uxPan = uxPan
        self.uxNoPan = uxNoPan
        self.uxNoCard = uxNoCard
    }
    
    public func toArray() -> [Double] {
        return [hasOcr ? 1.0 : 0.0, uxPan, uxNoPan, uxNoCard]
    }
}

public enum CenteredCardState {
    case numberSide
    case nonNumberSide
    case noCard
    
    public func hasCard() -> Bool {
        return self == .numberSide || self == .nonNumberSide
    }
}

public struct CreditCardOcrPrediction {
    public let image: CGImage
    public let number: String?
    public let expiryMonth: String?
    public let expiryYear: String?
    public let name: String?
    public let computationTime: Double
    public let numberBoxes: [CGRect]?
    public let expiryBoxes: [CGRect]?
    public let nameBoxes: [CGRect]?
    
    // this is only used by Card Verify and the Liveness check and filled in by the UxModel
    public var centeredCardState: CenteredCardState?
    public var uxFrameConfidenceValues: UxFrameConfidenceValues?
    
    public init(image: CGImage, number: String?, expiryMonth: String?, expiryYear: String?, name: String?, computationTime: Double, numberBoxes: [CGRect]?, expiryBoxes: [CGRect]?, nameBoxes: [CGRect]?, centeredCardState: CenteredCardState? = nil, uxFrameConfidenceValues: UxFrameConfidenceValues? = nil) {
        
        self.image = image
        self.number = number
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.name = name
        self.computationTime = computationTime
        self.numberBoxes = numberBoxes
        self.expiryBoxes = expiryBoxes
        self.nameBoxes = nameBoxes
        self.centeredCardState = centeredCardState
        self.uxFrameConfidenceValues = uxFrameConfidenceValues
    }
    
    public static func emptyPrediction(cgImage: CGImage) -> CreditCardOcrPrediction {
        CreditCardOcrPrediction(image: cgImage, number: nil, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
    }
    
    public var expiryForDisplay: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return "\(month)/\(year)"
    }
    
    public var expiryAsUInt: (UInt, UInt)? {
        guard let month = expiryMonth.flatMap({ UInt($0) }) else { return nil }
        guard let year = expiryYear.flatMap({ UInt($0) }) else { return nil }
        
        return (month, year)
    }
    
    public var numberBox: CGRect? {
        let xmin = numberBoxes?.map { $0.minX }.min() ?? 0.0
        let xmax = numberBoxes?.map { $0.maxX }.max() ?? 0.0
        let ymin = numberBoxes?.map { $0.minY }.min() ?? 0.0
        let ymax = numberBoxes?.map { $0.maxY }.max() ?? 0.0
        return CGRect(x: xmin, y: ymin, width: (xmax - xmin), height: (ymax - ymin))
    }
    
    public var expiryBox: CGRect? {
        return expiryBoxes.flatMap { $0.first }
    }
    
    static func likelyExpiry(_ string: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: "^.*(0[1-9]|1[0-2])[./]([1-2][0-9])$") else {
            return nil
        }

        let result = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        
        if result.count == 0 {
            return nil
        }
        
        guard let nsrange1 = result.first?.range(at: 1),
            let range1 = Range(nsrange1, in: string) else { return nil }
        guard let nsrange2 = result.first?.range(at: 2),
            let range2 = Range(nsrange2, in: string) else { return nil }

        return (String(string[range1]), String(string[range2]))
    }
    
    static func pan(_ text: String) -> String? {
        let digitsAndSpace = text.reduce(true) { $0 && (($1 >= "0" && $1 <= "9") || $1 == " ") }
        let number = text.compactMap { $0 >= "0" && $0 <= "9" ? $0 : nil }.map { String($0) }.joined()
        
        guard digitsAndSpace else { return nil }
        guard CreditCardUtils.isValidNumber(cardNumber: number) else { return nil }
        return number
    }
}
