//
//  API.swift
//  Lab Fees
//
//  Created by Sam King on 11/11/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import Foundation
import CardScan

struct Api {
    
    struct ApiError: Error {
        var message: String
        var code: String
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
        }
    }
    
    // XXX FIXME we should move to a more traditional error handling method
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    //static var baseUrl = "https://lab-fees.appspot.com"
    //static var baseUrl = "http://localhost:8080"
    static var baseUrl = "http://10.0.0.61:8080"
    //static var baseUrl = "http://192.168.2.1:8080"
    static let defaultError = ApiError(response: [:])
    
    static func configuration() -> URLSessionConfiguration {
        // XXX FIXME there has to be a better way to do this than allocating a new config with each API
        // call and using it
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        //config.httpAdditionalHeaders = Storage.authToken.flatMap { ["x-authtoken": $0] }
        return config
    }
    
    static func ApiCall(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        // XXX FIXME we should add some logging here to know when something has gone wrong
        
        guard let url = URL(string: baseUrl + endpoint) else {
            // do something
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
                    completion(responseData, nil)
                } else {
                    completion(nil, ApiError(response: responseData))
                }
            }
            }.resume()
    }
    
    
    static func trainingEmbossedDigits(imagesAndLabels: [[String: String]]) {
        ApiCall(endpoint: "/training/embossed_digits",
                parameters: ["embossed_digits": imagesAndLabels],
                completion: {_,_ in })
    }
    
    static func trainingImages(images: [[String: String]]) {
        ApiCall(endpoint: "/training/images",
                parameters: ["images": images],
                completion: {_,_ in })
    }
    
    static func trainingDetectionImage(imagePng: String) {
        ApiCall(endpoint: "/training/detection_image",
                parameters: ["image_png": imagePng],
                completion: {_,_ in })
    }
    
    static func scanStats(scanStats: ScanStats) {
        /*
        ApiCall(endpoint: "/scan_stats",
                parameters: ["device_id": "0xdeadbeef",
                             "email": "naeth@gmail.com",
                             "scan_stats": scanStats.toDictionaryForServer()],
                completion: {_,_ in })*/
    }
}

