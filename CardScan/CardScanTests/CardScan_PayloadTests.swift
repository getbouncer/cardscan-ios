//
//  CardScanTests.swift
//  CardScanTests
//
//  Created by Jaime Park on 5/3/21.
//

import XCTest
@testable import CardScan

class CardScanTests: XCTestCase {
    
    func testScanStatsPayloadEquality() {
        let scanStats = ScanStats()
        var scanStatsDict: [String: Any] = [:]
        scanStatsDict["scan_stats"] = scanStats.toDictionaryForAnalytics()
        scanStatsDict["platform"] = "ios"
        scanStatsDict["os"] = DeviceUtils.osVersion
        scanStatsDict["device_type"] = DeviceUtils.name
        scanStatsDict["device_locale"] = DeviceUtils.locale
        scanStatsDict["build"] = DeviceUtils.build
        scanStatsDict["sdk_version"] = AppInfoUtils.sdkVersion
        
        // Turn different forms into Data type
        guard let scanStatsPayload1 = try? JSONSerialization.data(withJSONObject: scanStatsDict),
              let scanStatsPayload2 = try? JSONEncoder().encode(scanStats.createPayload()) else {
            XCTAssert(false, "Payload data can't be serialized")
            return
        }

        // Turn data into JSON
        do{
            let json1 = try JSONSerialization.jsonObject(with: scanStatsPayload1, options: []) as? [String : Any]
            let json2 = try JSONSerialization.jsonObject(with: scanStatsPayload2, options: []) as? [String : Any]
            XCTAssert(NSDictionary(dictionary: json1!).isEqual(to: json2!))
        } catch{
            XCTAssert(false, "Payload could not be jsonified")
        }
    }
}
