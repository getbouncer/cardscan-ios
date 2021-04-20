//
//  Stats.swift
//  CardScan
//
//  Created by Jaime Park on 4/15/21.
//

import Foundation

struct ScanStatisticsPayload: Encodable {
    let device = Device()
    let scanStats: ScanStatistics
    let sdkVersion = AppInfoUtils.getSdkVersion()
    
    enum CodingKeys: String, CodingKey {
        case scanStats = "scan_stats"
        case sdkVersion = "sdk_version"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scanStats, forKey: .scanStats)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try device.encode(to: encoder)
    }
}

struct ScanStatistics: Encodable {
    let scans: Int
    let cardsDetected: Int
    let torchOn: Bool
    let orientation: String
    let success: Bool
    let duration: Double
    let model: String
    let permissionGranted: String
    let deviceType: String = DeviceUtils.getDeviceType()
    let userCanceled: Bool
    
    enum CodingKeys: String, CodingKey {
        case scans = "scans"
        case cardDetected = "cards_detected"
        case torchOn = "torch_on"
        case orientation = "orientation"
        case success = "success"
        case duration = "duration"
        case model = "model"
        case permissionGranted = "permission_granted"
        case deviceType = "device_type"
        case userCanceled = "user_canceled"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scans, forKey: .scans)
        try container.encode(cardsDetected, forKey: .cardDetected)
        try container.encode(torchOn, forKey: .torchOn)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(success, forKey: .success)
        try container.encode(duration, forKey: .duration)
        try container.encode(model, forKey: .model)
        try container.encode(permissionGranted, forKey: .permissionGranted)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(userCanceled, forKey: .userCanceled)
    }
}
