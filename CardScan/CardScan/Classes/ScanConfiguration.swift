import Foundation

@objc public enum ScanPerformance: Int {
    case fastScan
    case accurateScan
}

@objc public class ScanConfiguration: NSObject {
    @objc public var runOnOldDevices = false
    @objc public var setPreviouslyDeniedDevicesAsIncompatible = false
    @objc public static var scanPerformancePriority: ScanPerformance = .fastScan
}
