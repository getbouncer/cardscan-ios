import Foundation

public struct CreditCardUtils {
    static let cvcLengthAmericanExpress = 4
    static let cvcLength = 3
    
    static let maxPanLength = 16
    static let maxPanLengthAmericanExpress = 15
    static let maxPanLengthDinersClub = 14

    static let prefixesAmericanExpress = ["34", "37"]
    static let prefixesDinersClub = ["300", "301", "302", "303", "304", "305", "309", "36", "38", "39"]
    static let prefixesDiscover = ["6011", "64", "65"]
    static let prefixesJcb = ["35"]
    static let prefixesMastercard = ["2221", "2222", "2223", "2224", "2225", "2226",
                                     "2227", "2228", "2229", "223", "224", "225", "226",
                                     "227", "228", "229", "23", "24", "25", "26", "270",
                                     "271", "2720", "50", "51", "52", "53", "54", "55",
                                     "67"]
    static let prefixesUnionPay = ["62"]
    static let prefixesVisa = ["4"]
    
    // https://en.wikipedia.org/wiki/Luhn_algorithm
    // assume 16 digits are for MC and Visa (start with 4, 5) and 15 is for Amex
    // which starts with 3
    public static func luhnCheck(_ cardNumber: String) -> Bool {
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
    
    public static func isValidBin(number: String) -> Bool {
        return isAmex(number: number) || isDiscover(number: number) || isVisa(number: number) || isMastercard(number: number) || isUnionPay(number: number) || isJcb(number: number) || isDinersClub(number: number)
    }
    
    public static func isAmex(number: String) -> Bool {
        let prefix = String(number.prefix(2))
        return number.count == maxPanLengthAmericanExpress && prefixesAmericanExpress.contains(prefix)
    }
    
    public static func isUnionPay(number: String) -> Bool {
        // Note: there is a little confusion over discover vs unionpay
        // since some of the bin ranges overlap, but my guess is that
        // it's unionpay but might be using the discover network
        // behind the scenes.
        // https://www.unionpayintl.com/en/mediaCenter/brandCenter/brandEmbodiment/
        let prefix = String(number.prefix(2))
        return number.count == maxPanLength && prefixesUnionPay.contains(prefix)
    }
    
    public static func isDiscover(number: String) -> Bool {
        let prefix2 = String(number.prefix(2))
        let prefix4 = String(number.prefix(4))
        return number.count == maxPanLength && (prefixesDiscover.contains(prefix2) || prefixesDiscover.contains(prefix4))
    }
    
    public static func isMastercard(number: String) -> Bool {
        let prefix2 = String(number.prefix(2))
        let prefix3 = String(number.prefix(3))
        let prefix4 = String(number.prefix(4))
        
        return number.count == maxPanLength && (prefixesMastercard.contains(prefix2) || prefixesMastercard.contains(prefix3) || prefixesMastercard.contains(prefix4))
    }
    
    public static func isVisa(number: String) -> Bool {
        let prefix = String(number.prefix(1))
        return number.count == maxPanLength && prefixesVisa.contains(prefix)
    }
    
    public static func isJcb(number: String) -> Bool {
        let prefix = String(number.prefix(2))
        return number.count == maxPanLength && prefixesJcb.contains(prefix)
    }
    
    public static func isDinersClub(number: String) ->  Bool {
        let prefix2 = String(number.prefix(2))
        let prefix3 = String(number.prefix(3))
        return number.count == maxPanLengthDinersClub && (prefixesDinersClub.contains(prefix2) || prefixesDinersClub.contains(prefix3))
    }
    
    public static func format(number: String) -> String {
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
