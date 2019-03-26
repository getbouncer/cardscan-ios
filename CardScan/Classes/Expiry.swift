import Foundation

public struct Expiry: Hashable {
    public let string: String
    public let month: UInt
    public let year: UInt
    
    public static func == (lhs: Expiry, rhs: Expiry) -> Bool {
        return lhs.string == rhs.string
    }
    
    public func hash(into hasher: inout Hasher) {
        self.string.hash(into: &hasher)
    }
    
    public var hashValue: Int {
        return self.string.hashValue
    }
    
    func display() -> String {
        let twoDigitYear = self.year % 100
        return String(format: "%02d/%02d", self.month, twoDigitYear)
    }
    
    static func from(image: CGImage, within rect: CGRect) -> Expiry? {
        guard let digits = RecognizedDigits.from(image: image, within: rect) else {
            return nil
        }
        
        let (string, _) = digits.toString()
        
        if string.count != 4 {
            return nil
        }
        
        let monthString = String(string.prefix(2))
        let yearString = String(string.suffix(2))
            
        if monthString.count != 2 && yearString.count != 2 {
            return nil
        }
            
        guard let month = UInt(monthString) else {
            return nil
        }
            
        if month <= 0 || month > 12 {
            return nil
        }
            
        guard let year = UInt(yearString) else {
            return nil
        }
            
        let now = Date()
        let currentYear = Calendar.current.component(.year, from: now)
        let currentMonth = Calendar.current.component(.month, from: now)
        let fullYear = 2000 + year
        if fullYear < currentYear || fullYear >= (currentYear + 10) {
            return nil
        }
        
        if fullYear == currentYear && month < currentMonth {
            return nil
        }
        
        return Expiry(string: string, month: month, year: fullYear)
    }
}
