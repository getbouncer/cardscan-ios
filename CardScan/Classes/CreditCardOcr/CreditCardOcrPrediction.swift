//
//  CreditCardOcrPrediction.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import Foundation

struct CreditCardOcrPrediction {
    let number: String?
    let expiryMonth: String?
    let expiryYear: String?
    let name: String?
    let computationTime: Double
    
    var expiryForDisplay: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return "\(month)/\(year)"
    }
    
    static func likelyExpiry(_ string: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: "^.*(0[1-9]|1[0-2])\\/([1-2][0-9])$") else {
            return nil
        }

        let result = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        
        if result.count == 0 {
            return nil
        }
        
        let range1 = Range(result.first!.range(at: 1), in: string)!
        let range2 = Range(result.first!.range(at: 2), in: string)!

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
