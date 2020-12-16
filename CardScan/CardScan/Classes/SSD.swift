//
// SSD.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class SSDInput : MLFeatureProvider {

    /// 0 as color (kCVPixelFormatType_32BGRA) image buffer, 300 pixels wide by 300 pixels high
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
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class SSDOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// MultiArray of shape (1, 1, 1, 2766, 8). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var scores: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "scores")!.multiArrayValue
    }()!

    /// MultiArray of shape (1, 1, 1, 2766, 4). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var boxes: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "boxes")!.multiArrayValue
    }()!

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(scores: MLMultiArray, boxes: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["scores" : MLFeatureValue(multiArray: scores), "boxes" : MLFeatureValue(multiArray: boxes)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class SSD {
    var model: MLModel

/// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: SSD.self)
        return bundle.url(forResource: "SSD", withExtension:"mlmodelc")!
    }

    /**
        Construct a model with explicit path to mlmodelc file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration
        - parameters:
           - configuration: the desired model configuration
           - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct a model with explicit path to mlmodelc file and configuration
        - parameters:
           - url: the file url of the model
           - configuration: the desired model configuration
           - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    init(contentsOf url: URL, configuration: MLModelConfiguration) throws {
        self.model = try MLModel(contentsOf: url, configuration: configuration)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as SSDInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOutput
    */
    func prediction(input: SSDInput) throws -> SSDOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as SSDInput
           - options: prediction options 
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOutput
    */
    func prediction(input: SSDInput, options: MLPredictionOptions) throws -> SSDOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return SSDOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - _0 as color (kCVPixelFormatType_32BGRA) image buffer, 300 pixels wide by 300 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SSDOutput
    */
    func prediction(_0: CVPixelBuffer) throws -> SSDOutput {
        let input_ = SSDInput(_0: _0)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface
        - parameters:
           - inputs: the inputs to the prediction as [SSDInput]
           - options: prediction options 
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as [SSDOutput]
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    func predictions(inputs: [SSDInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [SSDOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [SSDOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  SSDOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
