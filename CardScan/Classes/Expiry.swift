import Foundation

@objc public class Expiry: NSObject {
    @objc public let string: String
    @objc public let month: UInt
    @objc public let year: UInt
    
    public static func == (lhs: Expiry, rhs: Expiry) -> Bool {
        return lhs.string == rhs.string
    }
    
    public init(string: String, month: UInt, year: UInt) {
        self.string = string
        self.month = month
        self.year = year
    }
    
//    public func hash(into hasher: inout Hasher) {
//        self.string.hash(into: &hasher)
//    }
//
//    public var hashValue: Int {
//        return self.string.hashValue
//    }
    
    @objc func display() -> String {
        let twoDigitYear = self.year % 100
        return String(format: "%02d/%02d", self.month, twoDigitYear)
    }
}
