//
//  ModelConfigResponse.swift
//  CardScan
//
//  Created by Jaime Park on 8/17/20.
//

import Foundation

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
public struct ModelConfigResponse {
    public let modelVersion: String
    public let hash: String
    public let hashAlgorithm: String
    public let signedUrl: String
}
