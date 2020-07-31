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
    static public var apiKey: String?
    
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
                if "ok" == responseData["status"] as? String || endpoint == "/v1/drivers_license/verify" {
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
    
    static func getDeviceLocale() -> String? {
        return NSLocale.preferredLanguages.first
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
        apiParameters["device_locale"] = getDeviceLocale()
        apiParameters["build"] = build
        apiParameters["sdk_version"] = getSdkVersion()
        
        apiCall(endpoint: endpoint, parameters: apiParameters, completion: completion)
    }
    
    static public func getModelDownloadConfig(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        modelDownloadConfig(endpoint: endpoint, parameters: parameters, completion: completion)
    }
    
    private static func modelDownloadConfig(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        guard let baseUrl = self.baseUrl else {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        guard let url = urlWithQueryParameters(baseUrl: baseUrl, endpoint: endpoint, parameters: parameters) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }

        let session = URLSession(configuration: configuration())
        session.dataTask(with: url) { data, response, error in
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
                if "error" == responseData["status"] as? String {
                    completion(nil, ApiError(response: responseData))
                } else {
                    completion(responseData, nil)
                }
            }
        }.resume()
    }
    
    static func urlWithQueryParameters(baseUrl: String, endpoint: String, parameters: [String: Any]) -> URL? {
        let parametersDict: [String: String] = {
            var parametersDict: [String: String] = [:]
            for (key, value) in parameters {
                if let val = value as? String {
                    parametersDict[key] = val
                }
            }
            return parametersDict
        }()
        
        var components = URLComponents(string: baseUrl + endpoint)
        components?.queryItems = parametersDict.map { (key, value) in URLQueryItem(name: key, value: value) }
        let encodedQuery = components?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components?.percentEncodedQuery = encodedQuery
        return components?.url
    }
    
    static func scanStats(scanStats: ScanStats, completion: @escaping ApiCompletion) {
        self.apiCallWithDeviceInfo(endpoint: "/scan_stats", parameters: ["scan_stats": scanStats.toDictionaryForAnalytics()], completion: completion)
    }
}

