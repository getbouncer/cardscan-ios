//
//  ScanApi.swift
//  CardScan
//
//  Created by Jaime Park on 4/20/21.
//

import Foundation

struct ScanApi {
    static let STATS_PATH = "/scan_stats"
    
    static func uploadScanStats(payload: ScanStatisticsPayload, completion: @escaping (DefaultResponse?, Error?) -> Void) {
        let jsonEncoder = JSONEncoder()
        
        guard let requestData = try? jsonEncoder.encode(payload) else {
            print("Upload Scan Stats: Could not encode payload")
            return
        }
        
        ApiRequest.post(endpoint: STATS_PATH, requestData: requestData, completion: completion)
    }
}
