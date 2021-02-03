import Foundation

@objc public enum ScanPerformancePriority: Int {
    case fast
    case accurate
}

@objc public class ScanConfiguration: NSObject {
    @objc public var runOnOldDevices = false
    @objc public var setPreviouslyDeniedDevicesAsIncompatible = false
}
