import CoreML

@available(iOS 11.2, *)
public struct BundleURL{
    public static var bundleName = "CardScan"
    public static var extensionName = "bundle"
    
    static func compiledModel(forResource: String, withExtension: String) -> URL? {
    
        guard let bundleUrl = Bundle(for: FindFour.self).url(forResource: bundleName, withExtension: extensionName) else {
            print("bundleURL could not be found")
            return nil
        }
            
        guard let bundle = Bundle(url: bundleUrl) else {
            print("bundle with bundleURL could not be found")
            return nil
        }
            
        guard let modelcUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
            print("Could not find bundle named \"\(forResource).\(withExtension)\"")
            return nil
        }
        
        return modelcUrl
    }
}
