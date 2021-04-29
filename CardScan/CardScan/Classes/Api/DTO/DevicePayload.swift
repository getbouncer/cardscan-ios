//
//  DevicePayload.swift
//  CardVerify
//
//  Created by Jaime Park on 4/28/21.
//

import Foundation

struct DevicePayload: Encodable {
    let locale: String? = DeviceUtils.locale
    let deviceType: String = DeviceUtils.getDeviceType()
    let build: String = DeviceUtils.build
    let osVersion: String = DeviceUtils.osVersion
    let platform: String = DeviceUtils.platform
    let sdkVersion = AppInfoUtils.getSdkVersion()
    
    enum CodingKeys: String, CodingKey {
        case locale = "device_locale"
        case deviceType = "device_type"
        case build = "build"
        case osVersion = "os"
        case platform = "platform"
        case sdkVersion = "sdk_version"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(build, forKey: .build)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(platform, forKey: .platform)
        try container.encode(sdkVersion, forKey: .sdkVersion)
    }
}
