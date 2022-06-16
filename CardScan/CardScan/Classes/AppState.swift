import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
struct AppState {
    
    static let lock = DispatchSemaphore(value: 1)
    static private var isInBackground = false
    
    static var inBackground: Bool {
        get {
            lock.wait()
            let background = isInBackground
            lock.signal()
            return background
        }
        
        set(value) {
            lock.wait()
            isInBackground = value
            lock.signal()
        }
    }
}
