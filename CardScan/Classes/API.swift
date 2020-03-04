//
//  API.swift
//  Lab Fees
//
//  Created by Sam King on 11/11/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import Foundation

public struct Api {
    
    public struct ApiError: Error {
        var message: String
        var code: String
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
        }
    }
    
    // we use this for testing just to make sure that our fraudCheck APIs post
    // successfully
    public static var lastScanStatsSuccess: Date?
    
    // XXX FIXME we should move to a more traditional error handling method
    public typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    static public var baseUrl: String? = "https://api.getbouncer.com"
    static let defaultError = ApiError(response: [:])
    static let apiUrlNotSet = ApiError(response: ["error_message": "Your API.baseUrl or token isn't set",
                                                  "error_code": "api_baseurl_not_set"])
    static var apiKey: String?
    
    static func configuration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = apiKey.flatMap { ["x-bouncer-auth": $0] }
        return config
    }
    
    static func apiCall(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        guard let baseUrl = self.baseUrl else {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        guard let url = URL(string: baseUrl + endpoint) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }
        
        let session = URLSession(configuration: configuration())
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let requestData = try? JSONSerialization.data(withJSONObject: parameters) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }
        
        session.uploadTask(with: request, from: requestData) { data, response, error in
            guard let rawData = data else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            let jsonData = try? JSONSerialization.jsonObject(with: rawData)
            guard let responseData = jsonData as? [String: Any] else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            DispatchQueue.main.async {
                if "ok" == responseData["status"] as? String {
                    Api.lastScanStatsSuccess = Date()
                    completion(responseData, nil)
                } else {
                    completion(nil, ApiError(response: responseData))
                }
            }
        }.resume()
    }
    
    static func deviceType() -> String {
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
    
    static func getSdkVersion() -> String? {
        guard let bundle = CSBundle.bundle() else {
            return nil
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"].flatMap { $0 as? String }
    }
    
    static public func apiCallWithDeviceInfo(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        let version = ProcessInfo().operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "0000"
        
        var apiParameters = parameters
        apiParameters["platform"] = "ios"
        apiParameters["os"] = osVersion
        apiParameters["device_type"] = deviceType()
        apiParameters["build"] = build
        apiParameters["sdk_version"] = getSdkVersion()
        
        apiCall(endpoint: endpoint, parameters: apiParameters, completion: completion)
    }
    
    static func scanStats(scanStats: ScanStats, completion: @escaping ApiCompletion) {
        self.apiCallWithDeviceInfo(endpoint: "/scan_stats", parameters: ["scan_stats": scanStats.toDictionaryForAnalytics()], completion: completion)
    }
}

