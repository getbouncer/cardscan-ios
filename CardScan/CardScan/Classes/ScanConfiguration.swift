import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
@objc public enum ScanPerformance: Int {
    case fast
    case accurate
}

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
@objc public class ScanConfiguration: NSObject {
    @objc public var runOnOldDevices = false
    @objc public var setPreviouslyDeniedDevicesAsIncompatible = false
}
