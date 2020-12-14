//
//  MyAppsApi.swift
//  CardScanSystemTest
//
//  Created by Jaime Park on 11/5/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import Foundation
import CardScan

struct MyAppsApi {
    public struct ApiError: Error {
        var message: String
        var code: String
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
        }
    }
    
    public typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    static public var baseUrl: String? = "https://api.getbouncer.com"
    static let defaultError = ApiError(response: [:])
    static let apiUrlNotSet = ApiError(response: ["error_message": "Your API.baseUrl or token isn't set",
                                                  "error_code": "api_baseurl_not_set"])
    static var apiKey: String? = "shsomuoRjIzoxCSzZXC-0a8pkP62ggxd"

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
            
            guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            DispatchQueue.main.async {
                completion(responseData, nil)
            }
        }.resume()
    }
    
    static public func apiCallWithDeviceInfo(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        if baseUrl == nil || apiKey == nil {
            DispatchQueue.main.async { completion(nil, apiUrlNotSet) }
            return
        }

        apiCall(endpoint: endpoint, parameters: parameters, completion: completion)
    }
    
    static func fraudCheck(parameters: [String: Any], completion: @escaping MyAppsApi.ApiCompletion) {
        apiCallWithDeviceInfo(endpoint: "/v1/card/verify",
                              parameters: parameters,
                              completion: completion)
    }
}
