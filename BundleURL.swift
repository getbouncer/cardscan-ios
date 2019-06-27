import CoreML

@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
//model name : "FindFour.mlmodelc"
struct BundleURL{
    static func bundleUrl(modelName: String) -> URL?{
        var modelcFile: URL
        if let documentDirectory =
            try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) {
                modelcFile = documentDirectory.appendingPathComponent(modelName)
            }
        
        if !FileManager.default.fileExists(atPath: modelcFile.path) {
            guard let bundleUrl = Bundle(for: FindFour.self).url(forResource: "CardScan", withExtension: "bundle") else {
                print("Could not find bundleURL")
                return nil
            }
            
            guard let bundle = Bundle(url: bundleUrl) else {
                return nil
            }
            
            let modelUrl = bundle.url(forResource: "FindFour", withExtension: "bin")
            
            if let compiledUrl =
                try? MLModel.compileModel(at: modelUrl){
                try? FileManager.default.moveItem(at: compiledUrl!, to: modelcFile)
            }
        
        }
        
        return modelcFile
    }
}
