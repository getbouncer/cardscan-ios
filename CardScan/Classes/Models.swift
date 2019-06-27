
//
// This file was automatically generated and edited.
//

import CoreML

enum InBackgroundError: Error {
    case appIsInTheBackground
}

/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FindFourInput : MLFeatureProvider {
    
    /// input1 as color (kCVPixelFormatType_32BGRA) image buffer, 480 pixels wide by 302 pixels high
    var input1: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["input1"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input1") {
            return MLFeatureValue(pixelBuffer: input1)
        }
        return nil
    }
    
    init(input1: CVPixelBuffer) {
        self.input1 = input1
    }
}

/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FindFourOutput : MLFeatureProvider {
    
    /// Source provided by CoreML
    
    private let provider : MLFeatureProvider
    
    
    /// output1 as 3 x 34 x 51 3-dimensional array of doubles
    lazy var output1: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "output1")!.multiArrayValue
        }()!
    
    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }
    
    init(output1: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["output1" : MLFeatureValue(multiArray: output1)])
    }
    
    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FindFour {
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
     - input: the input to the prediction as FindFourInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FindFourOutput
     */
    func prediction(input: FindFourInput) throws -> FindFourOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }
    
    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as FindFourInput
     - options: prediction options
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FindFourOutput
     */
    func prediction(input: FindFourInput, options: MLPredictionOptions) throws -> FindFourOutput {
        if AppState.inBackground {
            throw InBackgroundError.appIsInTheBackground
        }
        let outFeatures = try model.prediction(from: input, options:options)
        return FindFourOutput(features: outFeatures)
    }
    
    /**
     Make a prediction using the convenience interface
     - parameters:
     - input1 as color (kCVPixelFormatType_32BGRA) image buffer, 480 pixels wide by 302 pixels high
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FindFourOutput
     */
    func prediction(input1: CVPixelBuffer) throws -> FindFourOutput {
        let input_ = FindFourInput(input1: input1)
        return try self.prediction(input: input_)
    }
}

/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FourRecognizeInput : MLFeatureProvider {
    
    /// input1 as color (kCVPixelFormatType_32BGRA) image buffer, 80 pixels wide by 36 pixels high
    var input1: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["input1"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input1") {
            return MLFeatureValue(pixelBuffer: input1)
        }
        return nil
    }
    
    init(input1: CVPixelBuffer) {
        self.input1 = input1
    }
}

/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FourRecognizeOutput : MLFeatureProvider {
    
    /// Source provided by CoreML
    
    private let provider : MLFeatureProvider
    
    
    /// output1 as 11 x 1 x 17 3-dimensional array of doubles
    lazy var output1: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "output1")!.multiArrayValue
        }()!
    
    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }
    
    init(output1: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["output1" : MLFeatureValue(multiArray: output1)])
    }
    
    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class FourRecognize {
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
     - input: the input to the prediction as FourRecognizeInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FourRecognizeOutput
     */
    func prediction(input: FourRecognizeInput) throws -> FourRecognizeOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }
    
    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as FourRecognizeInput
     - options: prediction options
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FourRecognizeOutput
     */
    func prediction(input: FourRecognizeInput, options: MLPredictionOptions) throws -> FourRecognizeOutput {
        if AppState.inBackground {
            throw InBackgroundError.appIsInTheBackground
        }
        let outFeatures = try model.prediction(from: input, options:options)
        return FourRecognizeOutput(features: outFeatures)
    }
    
    /**
     Make a prediction using the convenience interface
     - parameters:
     - input1 as color (kCVPixelFormatType_32BGRA) image buffer, 80 pixels wide by 36 pixels high
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as FourRecognizeOutput
     */
    func prediction(input1: CVPixelBuffer) throws -> FourRecognizeOutput {
        let input_ = FourRecognizeInput(input1: input1)
        return try self.prediction(input: input_)
    }
}
