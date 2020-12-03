
//
// SSDOcr.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SSDOcrInput : MLFeatureProvider {

    /// 0 as color (kCVPixelFormatType_32BGRA) image buffer, 600 pixels wide by 375 pixels high
    var _0: CVPixelBuffer

    var featureNames: Set<String> {
        get {
            return ["0"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "0") {
            return MLFeatureValue(pixelBuffer: _0)
        }
        return nil
    }
    
    init(_0: CVPixelBuffer) {
        self._0 = _0
    }
}

/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SSDOcrOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// MultiArray of shape (1, 1, 1, 3420, 10). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var scores: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "scores")!.multiArrayValue
    }()!

    /// MultiArray of shape (1, 1, 1, 3420, 4). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var boxes: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "boxes")!.multiArrayValue
    }()!

    /// MultiArray of shape (1, 1, 1, 3420, 1). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var _594: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "594")!.multiArrayValue
    }()!

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(scores: MLMultiArray, boxes: MLMultiArray, _594: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["scores" : MLFeatureValue(multiArray: scores), "boxes" : MLFeatureValue(multiArray: boxes), "594" : MLFeatureValue(multiArray: _594)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SSDOcr {
    var model: MLModel
    
    /**
        Construct a model with explicit path to mlmodelc file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as SSDOcrInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOcrOutput
    */
    func prediction(input: SSDOcrInput) throws -> SSDOcrOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as SSDOcrInput
           - options: prediction options
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOcrOutput
    */
    func prediction(input: SSDOcrInput, options: MLPredictionOptions) throws -> SSDOcrOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return SSDOcrOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - _0 as color (kCVPixelFormatType_32BGRA) image buffer, 600 pixels wide by 375 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOcrOutput
    */
    func prediction(_0: CVPixelBuffer) throws -> SSDOcrOutput {
        let input_ = SSDOcrInput(_0: _0)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface
        - parameters:
           - inputs: the inputs to the prediction as [SSDOcrInput]
           - options: prediction options
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as [SSDOcrOutput]
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    func predictions(inputs: [SSDOcrInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [SSDOcrOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [SSDOcrOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  SSDOcrOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
