//
//  DeviceUtils.swift
//  CardScan
//
//  Created by Jaime Park on 12/30/20.
//

import CoreTelephony
import Foundation
import UIKit

struct ClientIdsUtils {
    static let vendorId: String? = getVendorId()
    
    static internal func getVendorId() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
}

struct DeviceUtils {
    static let ids = ClientIds(vendorId: ClientIdsUtils.vendorId)
    static let name: String = getDeviceType()
    static let bootCount: Int? = nil
    static let locale: String? = getDeviceLocale()
    static let carrier: String? = getCarrier()
    static let networkOperator: String? = nil
    // double check how phone types are done in ios
    static let phoneType: Int? = 1
    static let phoneCount: Int? = 1
    
    static let osVersion: String = getOsVersion()
    static let platform: String = "ios"
    
    static internal func getDeviceType() -> String{
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceType = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                return ""
            }
            
            if charDigit == 0 {
                break
            }
            
            deviceType += String(UnicodeScalar(UInt8(charDigit)))
        }
        
        return deviceType
    }
    
    static internal func getDeviceLocale() -> String? {
        return NSLocale.preferredLanguages.first
    }
    
    static internal func getCarrier() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let carrierInfo = networkInfo.subscriberCellularProvider else {
            return nil
        }

        return carrierInfo.carrierName
    }
    
    static internal func getOsVersion() -> String {
        let version = ProcessInfo().operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        return osVersion
    }
}
