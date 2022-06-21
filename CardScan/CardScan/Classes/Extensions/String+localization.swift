import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
extension String {
    func localize() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: CSBundle.bundle() ?? Bundle.main, value: self, comment: self)
    }
}
