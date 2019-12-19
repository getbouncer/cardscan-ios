import Foundation

public enum CardNetwork: String {
    case VISA = "Visa"
    case MASTERCARD = "Mastercard"
    case AMEX = "Amex"
    case DISCOVER = "Discover"
    case UNIONPAY = "Union Pay"
    case JCB = "Jcb"
    case DINERSCLUB = "Diners Club"
    case UNKNOWN = "Unknown"
}

public struct CreditCardUtils {
    static let maxPanLength = 16
    static let maxPanLengthAmericanExpress = 15
    static let maxPanLengthDinersClub = 14

    private static let prefixesAmericanExpress = ["34", "37"]
    private static let prefixesDinersClub = ["300", "301", "302", "303", "304", "305", "309", "36", "38", "39"]
    private static let prefixesDiscover = ["6011", "64", "65"]
    private static let prefixesJcb = ["35"]
    private static let prefixesMastercard = ["2221", "2222", "2223", "2224", "2225", "2226",
                                     "2227", "2228", "2229", "223", "224", "225", "226",
                                     "227", "228", "229", "23", "24", "25", "26", "270",
                                     "271", "2720", "50", "51", "52", "53", "54", "55",
                                     "67"]
    private static let prefixesUnionPay = ["62"]
    private static let prefixesVisa = ["4"]
    
    
    public static func isValidNumber(cardNumber: String) -> Bool {
        return isValidLuhnNumber(cardNumber: cardNumber) && isValidLength(cardNumber: cardNumber)
    }
    
    // https://en.wikipedia.org/wiki/Luhn_algorithm
    // assume 16 digits are for MC and Visa (start with 4, 5) and 15 is for Amex
    // which starts with 3
    static func isValidLuhnNumber(cardNumber: String) -> Bool {
        if cardNumber.isEmpty || !isValidBin(cardNumber: cardNumber){
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
    
    static func isValidBin(cardNumber: String) -> Bool {
        determineCardNetwork(cardNumber: cardNumber) != CardNetwork.UNKNOWN
    }
    
    static func isValidLength(cardNumber: String) -> Bool {
        return isValidLength(cardNumber: cardNumber, network: determineCardNetwork(cardNumber: cardNumber))
    }

    static func isValidLength(cardNumber: String, network: CardNetwork ) -> Bool {
        let cardNumber = cardNumber.trimmingCharacters(in: .whitespaces)
        let cardNumberLength = cardNumber.count
        
        if cardNumber.isEmpty || network == CardNetwork.UNKNOWN {
            return false
        }
        
        switch network {
        case CardNetwork.AMEX:
            return cardNumberLength == maxPanLengthAmericanExpress
        case CardNetwork.DINERSCLUB:
            return cardNumberLength == maxPanLengthDinersClub
        default:
            return cardNumberLength == maxPanLength
        }
    }
    
    public static func determineCardNetwork(cardNumber: String) -> CardNetwork {
        let cardNumber = cardNumber.trimmingCharacters(in: .whitespaces)
        
        if cardNumber.isEmpty {
            return CardNetwork.UNKNOWN
        }
        
        switch true {
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesAmericanExpress):
            return CardNetwork.AMEX
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesDiscover):
            return CardNetwork.DISCOVER
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesJcb):
            return CardNetwork.JCB
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesDinersClub):
            return CardNetwork.DINERSCLUB
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesVisa):
            return CardNetwork.VISA
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesMastercard):
            return CardNetwork.MASTERCARD
        case hasAnyPrefix(cardNumber: cardNumber, prefixes: prefixesUnionPay):
            return CardNetwork.UNIONPAY
        default:
            return CardNetwork.UNKNOWN
        }
    }
    
    static func hasAnyPrefix( cardNumber: String, prefixes: [String] ) -> Bool {
        return prefixes.filter { cardNumber.hasPrefix($0) }.count > 0
    }
    
    public static func format(cardNumber: String) -> String {
        if cardNumber.count == maxPanLength {
            return format16(cardNumber: cardNumber)
        } else if cardNumber.count == maxPanLengthAmericanExpress {
            return format15(cardNumber: cardNumber)
        } else {
            return cardNumber
        }
    }
    
    static func format15(cardNumber: String) -> String {
        var displayNumber = ""
        for (idx, char) in cardNumber.enumerated() {
            if idx == 4 || idx == 10 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
    
    static func format16(cardNumber: String) -> String {
        var displayNumber = ""
        for (idx, char) in cardNumber.enumerated() {
            if (idx % 4) == 0 && idx != 0 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
}
