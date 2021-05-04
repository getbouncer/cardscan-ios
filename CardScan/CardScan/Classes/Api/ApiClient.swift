//
//  ApiClient.swift
//  CardScan
//
//  Created by Jaime Park on 4/20/21.
//

import Foundation

class ApiClient {
    public static let shared = ApiClient()
    public static var apiKey: String?
    
    let baseUrl: URL? = URL(string: "https://api.getbouncer.com")
    let defaultSession = URLSession(configuration: defaultConfiguration)
    
    static let defaultConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = apiKey.map { ["x-bouncer-auth": $0] }
        return config
    }()
}
