import CoreML

@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
struct BundleURL{
    static func compiledModel(forResource: String, withExtension: String, modelName: String) -> URL? {
        guard let documentDirectory =
            try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else {
                print("Directory could not be found")
                return nil
        }
        
        let modelcFile = documentDirectory.appendingPathComponent(modelName)
        
        if !FileManager.default.fileExists(atPath: modelcFile.path) {
            guard let bundleUrl = Bundle(for: FindFour.self).url(forResource: "CardScan", withExtension: "bundle") else {
                print("bundleURL could not be found")
                return nil
            }
            
            guard let bundle = Bundle(url: bundleUrl) else {
                print("bundle with bundleURL could not be found")
                return nil
            }
            
            guard let modelUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
                print("Could not find bundle named \" \(forResource).\(withExtension)\" ")
                return nil
            }
            
            guard let compiledUrl = try? MLModel.compileModel(at: modelUrl) else {
                print("Model could not compile")
                return nil
            }
            
            guard let _ = try? FileManager.default.moveItem(at: compiledUrl, to: modelcFile) else {
                print("Could not move to modelcFile")
                return nil
            }
        }
        
        return modelcFile
    }
}
