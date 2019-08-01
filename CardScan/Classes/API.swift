//
//  API.swift
//  Lab Fees
//
//  Created by Sam King on 11/11/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import Foundation
import DeviceCheck

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
    public static var lastFraudCheckSuccess: Date?
    
    // XXX FIXME we should move to a more traditional error handling method
    public typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    static var baseUrl: String? = "https://api.getbouncer.com"
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
                    Api.lastFraudCheckSuccess = Date()
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
    
    static public func apiCallWithDeviceCheck(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        let version = ProcessInfo().operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "0000"
        
        // For deviceIds we use the vendorId because it gives end-users the ability
        // to change deviceIds by uninstalling the app. This is Apple's preferred
        // mechanisms for exposing privacy-friendly deviceIds:
        //
        // https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        var apiParameters = parameters
        apiParameters["platform"] = "ios"
        apiParameters["vendor_id"] = vendorId
        apiParameters["os"] = osVersion
        apiParameters["device_type"] = deviceType()
        apiParameters["build"] = build
        
        if #available(iOS 11.0, *) {
            DCDevice.current.generateToken { data, _ in
                apiParameters["device_check"] = data?.base64EncodedString() ?? ""
                apiCall(endpoint: endpoint,
                        parameters: apiParameters,
                        completion: completion)
            }
        } else {
            apiParameters["device_check"] = ""
            apiCall(endpoint: endpoint,
                    parameters: apiParameters,
                    completion: completion)
        }
    }
    
    static func fraudCheck(scanStats: ScanStats, completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }
        
        self.apiCallWithDeviceCheck(endpoint: "/fraud_check",
                                    parameters: ["scan_stats": scanStats.toDictionaryForFraudCheck()],
                                    completion: completion)
    }
    
    public static func cardTokenizedEvent(token: String, completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }

        self.apiCallWithDeviceCheck(endpoint: "/counter/increment",
                                    parameters: ["token": token,
                                                 "event": "card_tokenized"],
                                    completion: completion)
    }
}

