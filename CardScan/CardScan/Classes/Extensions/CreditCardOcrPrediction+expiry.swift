import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
extension CreditCardOcrPrediction {
    func expiryObject() -> Expiry? {
        if let month = self.expiryMonth.flatMap({ UInt($0) }),
            let year = self.expiryYear.flatMap({ UInt($0) }),
            let expiryString = self.expiryForDisplay {
            return Expiry(string: expiryString, month: month, year: year)
        } else {
            return nil
        }
    }
}
