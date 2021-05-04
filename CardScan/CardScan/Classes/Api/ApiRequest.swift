//
//  ApiRequest.swift
//  CardScan
//
//  Created by Jaime Park on 4/20/21.
//

import Foundation

struct DefaultApiError {
    struct ApiError: Error {
        let message: String
        let code: String
    }
    
    static let apiUrlNotSetError = ApiError(message: "Your API.baseUrl or token isn't set", code: "api_baseurl_not_set")
    static let requestError = ApiError(message: "There has been an error with the request", code: "request_error")
    static let parsingError = ApiError(message: "There has been an error with parsing the response", code: "response_parsing_error")
}

struct DefaultResponse: Decodable {
    let status: String
}

struct ApiRequest {
    static func post<ResponseType: Decodable>(endpoint: String, requestData: Data, completion: @escaping (ResponseType?, Error?) -> Void) {
        guard let baseUrl = ApiClient.shared.baseUrl else {
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.apiUrlNotSetError)
            }
            return
        }

        let url = baseUrl.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        ApiClient.shared.defaultSession.uploadTask(with: request, from: requestData) { data, response, error in
            self.parseResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    static func get<ResponseType: Decodable>(endpoint: String, requestData: Data, completion: @escaping (ResponseType?, Error?) -> Void) {
        guard let baseUrl = ApiClient.shared.baseUrl else {
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.apiUrlNotSetError)
            }
            return
        }

        let url = baseUrl.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        ApiClient.shared.defaultSession.dataTask(with: request) { data, response, error in
            self.parseResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    static func parseResponse<ResponseType: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (ResponseType?, Error?) -> Void) {
        guard error == nil else {
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.requestError)
            }
            return
        }
        
        guard let rawData = data, let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.requestError)
            }
            return
        }
        
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.requestError)
            }
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(ResponseType.self, from: rawData)
            DispatchQueue.main.async {
                completion(responseData, nil)
            }
        } catch {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                completion(nil, DefaultApiError.parsingError)
            }
        }
       
    }
}
