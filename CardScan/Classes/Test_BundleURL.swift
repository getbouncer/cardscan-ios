import CoreML

@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class TestBundle{
    var bundleUrl: URL?
    var bundle: Bundle?
    var modelUrl: URL?
    var compiled: Bool
    var compiledUrl: URL?
    var compiledModel: URL?
    
    
    init(){
        self.bundleUrl = nil
        self.bundle = nil
        self.modelUrl = nil
        self.compiled = false
        self.compiledUrl = nil
        self.compiledModel = nil
    }
    
    func setBundleUrl(){
        guard let bundleUrl = Bundle(for: FindFour.self).url(forResource: "CardScan", withExtension: "bundle") else {
            print("bundleURL could not be found")
            return
        }
        self.bundleUrl = bundleUrl
    }
    
    
    func setBundle(url: URL){
        guard let bundle = Bundle(url: url) else {
            print("bundle with bundleURL could not be found")
            return
        }
        self.bundle = bundle
    }
    
    func setModelUrl(bundle: Bundle?, forResource: String, withExtension: String){
        guard let modelUrl = bundle?.url(forResource: forResource, withExtension: withExtension) else {
            print("Could not find bundle named \" \(forResource).\(withExtension)\" ")
            return
        }
        self.modelUrl = modelUrl
    }
    
    func testCompiled(url: URL){
        guard let compiledUrl = try? MLModel.compileModel(at: url) else {
            print("Model could not compile")
            return
        }
        //Stores temporary location
        self.compiledUrl = compiledUrl
        //Stores if model was sucessfully compiled
        self.compiled = true
    }
    
    
    func compiledModel(forResource: String, withExtension: String, modelName: String){
        guard let documentDirectory =
            try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else {
                print("Directory could not be found")
                return
        }
        
        let modelcFile = documentDirectory.appendingPathComponent(modelName)
        
        if !FileManager.default.fileExists(atPath: modelcFile.path) {
            guard let bundleUrl = Bundle(for: FindFour.self).url(forResource: "CardScan", withExtension: "bundle") else {
                print("bundleURL could not be found")
                return
            }
            self.bundleUrl = bundleUrl
            
            guard let bundle = Bundle(url: bundleUrl) else {
                print("bundle with bundleURL could not be found")
                return
            }
            self.bundle = bundle
            
            guard let modelUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
                print("Could not find bundle named \" \(forResource).\(withExtension)\" ")
                return
            }
            self.modelUrl = modelUrl
            
            guard let compiledUrl = try? MLModel.compileModel(at: modelUrl) else {
                print("Model could not compile")
                return
            }
            
            self.compiled = true
            
            guard let _ = try? FileManager.default.moveItem(at: compiledUrl, to: modelcFile) else {
                print("Could not move to modelcFile")
                return
            }
        }
        
        self.compiledModel = modelcFile
    }
}
