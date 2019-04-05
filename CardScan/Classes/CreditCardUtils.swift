import Foundation

struct CreditCardUtils {
    // https://en.wikipedia.org/wiki/Luhn_algorithm
    // assume 16 digits are for MC and Visa (start with 4, 5) and 15 is for Amex
    // which starts with 3
    static func luhnCheck(_ cardNumber: String) -> Bool {
        if cardNumber.count == 0 {
            return false
        } else if !isValidBin(number: cardNumber) {
            return false
        }
        
        var sum = 0
        let reversedCharacters = cardNumber.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else { return false }
            switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit
            }
        }
        return sum % 10 == 0
    }
    
    static func isValidBin(number: String) -> Bool {
        return isAmex(number: number) || isDiscover(number: number) || isVisa(number: number) || isMastercard(number: number)
    }
    
    static func isAmex(number: String) -> Bool {
        guard let prefix = Int(String(number.prefix(2))) else {
            return false
        }
        
        return number.count == 15 && (prefix == 34 || prefix == 37)
    }
    
    static func isDiscover(number: String) -> Bool {
        guard let prefix2 = Int(String(number.prefix(2))), let prefix4 = Int(String(number.prefix(4))), let prefix6 = Int(String(number.prefix(6))) else {
            return false
        }
        
        return prefix2 == 64 || prefix2 == 65 || prefix4 == 6011 ||
            (prefix6 >= 622126 && prefix6 <= 622925) ||
            (prefix6 >= 624000 && prefix6 <= 626999) ||
            (prefix6 >= 628200 && prefix6 <= 628899)
    }
    
    static func isMastercard(number: String) -> Bool {
        guard let prefix2 = Int(String(number.prefix(2))), let prefix4 = Int(String(number.prefix(4))) else {
            return false
        }
        
        if number.count != 16 {
            return false
        }
        
        return (prefix2 >= 51 && prefix2 <= 55) || (prefix4 >= 2221 && prefix4 <= 2720)
    }
    
    static func isVisa(number: String) -> Bool {
        return number.count == 16 && number.starts(with: "4")
    }
    
    
    static func format(number: String) -> String {
        if number.count == 16 {
            return format16(number: number)
        } else if number.count == 15 {
            return format15(number: number)
        } else {
            return number
        }
    }
    
    static func format15(number: String) -> String {
        var displayNumber = ""
        for (idx, char) in number.enumerated() {
            if idx == 4 || idx == 10 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
    
    static func format16(number: String) -> String {
        var displayNumber = ""
        for (idx, char) in number.enumerated() {
            if (idx % 4) == 0 && idx != 0 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
}
