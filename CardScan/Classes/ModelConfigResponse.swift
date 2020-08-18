//
//  ModelConfigResponse.swift
//  CardScan
//
//  Created by Jaime Park on 8/17/20.
//

import Foundation

public struct ModelConfigResponse {
    let modelVersion: String
    let hash: String
    let hashAlgorithm: String
    let signedUrl: String
}
