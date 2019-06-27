import CoreML

@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class var BundleURL: URL{
    /// URL of model assuming it was installed in the same bundle as this class
    let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
    let modelcFile = documentDirectory.appendingPathComponent("FindFour.mlmodelc")
    
    if !FileManager.default.fileExists(atPath: modelcFile.path) {
        if let bundleUrl = Bundle(for: FindFour.self).url(forResource: "CardScan", withExtension: "bundle"){
            if let bundle = Bundle(url: bundleUrl){
                if let modelUrl = bundle.url(forResource: "FindFour", withExtension: "bin"){
                    let compiledUrl = try? MLModel.compileModel(at: modelUrl)
                    try? FileManager.default.moveItem(at: compiledUrl!, to: modelcFile)
                }
            }
        }
    }
    return modelcFile
}
