//
//  Device.swift
//  CardScan
//
//  Created by Jaime Park on 4/15/21.
//

import Foundation

struct Device: Encodable {
    let locale: String? = DeviceUtils.locale
    let build: String = DeviceUtils.build
    let osVersion: String = DeviceUtils.osVersion
    let platform: String = DeviceUtils.platform
    
    enum CodingKeys: String, CodingKey {
        case locale = "device_locale"
        case build = "build"
        case osVersion = "os"
        case platform = "platform"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encode(build, forKey: .build)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(platform, forKey: .platform)
    }
}
