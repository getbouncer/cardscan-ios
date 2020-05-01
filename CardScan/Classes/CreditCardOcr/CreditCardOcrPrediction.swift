//
//  CreditCardOcrPrediction.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import Foundation

struct CreditCardOcrPrediction {
    let image: CGImage
    let number: String?
    let expiryMonth: String?
    let expiryYear: String?
    let name: String?
    let computationTime: Double
    let numberBoxes: [CGRect]?
    let expiryBoxes: [CGRect]?
    let nameBoxes: [CGRect]?
    
    static func emptyPrediction(cgImage: CGImage) -> CreditCardOcrPrediction {
        CreditCardOcrPrediction(image: cgImage, number: nil, expiryMonth: nil, expiryYear: nil, name: nil, computationTime: 0.0, numberBoxes: nil, expiryBoxes: nil, nameBoxes: nil)
    }
    
    var expiryForDisplay: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return "\(month)/\(year)"
    }
    
    var expiryAsUInt: (UInt, UInt)? {
        guard let month = expiryMonth.flatMap({ UInt($0) }) else { return nil }
        guard let year = expiryYear.flatMap({ UInt($0) }) else { return nil }
        
        return (month, year)
    }
    
    var numberBox: CGRect? {
        let xmin = numberBoxes?.map { $0.minX }.min() ?? 0.0
        let xmax = numberBoxes?.map { $0.maxX }.max() ?? 0.0
        let ymin = numberBoxes?.map { $0.minY }.min() ?? 0.0
        let ymax = numberBoxes?.map { $0.maxY }.max() ?? 0.0
        return CGRect(x: xmin, y: ymin, width: (xmax - xmin), height: (ymax - ymin))
    }
    
    var expiryBox: CGRect? {
        return expiryBoxes.flatMap { $0.first }
    }
    
    static func likelyExpiry(_ string: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: "^.*(0[1-9]|1[0-2])\\/([1-2][0-9])$") else {
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
