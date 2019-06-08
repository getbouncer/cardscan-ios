import CoreML

struct ModelDownloader {
    
    struct ModelDownload {
        let url: String
        let compiledName: String
    }
    
    static var findFourModelDownload: ModelDownload? = ModelDownload(url: "https://lab-fees.appspot.com/videos/FindFour.bin", compiledName: "FindFour.mlmodelc")
    static var fourRecognizeModelDownload: ModelDownload? = nil
    
    static func modelDownloadData() -> [ModelDownload] {
        return [findFourModelDownload, fourRecognizeModelDownload].compactMap() { $0 }
    }
    
    static func downloadedSuccessfully() -> Bool {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                             appropriateFor:nil, create:false)
        // check to make sure that we downloaded and compiled all of the models we were supposed to
        for data in modelDownloadData() {
            let destinationFile = documentDirectory.appendingPathComponent(data.compiledName)
            if !FileManager.default.fileExists(atPath: destinationFile.path) {
                return false
            }
        }
        return true
    }
    
    @available(iOS 11.0, *)
    static func download() -> Bool {
        let session = URLSession(configuration: .ephemeral)
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        let dispatchGroup = DispatchGroup()
        
        for data in modelDownloadData() {
            let destinationFile = documentDirectory.appendingPathComponent(data.compiledName)
            if !FileManager.default.fileExists(atPath: destinationFile.path) {
                guard let url = URL(string: data.url) else {
                    return false
                }
                
                dispatchGroup.enter()
                session.downloadTask(with: url) { (location: URL?, response: URLResponse?, error: Error?) in
                    guard let location = location, let compiledUrl = try? MLModel.compileModel(at: location) else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    // just swallow it
                    try? FileManager.default.moveItem(at: compiledUrl, to: destinationFile)
                    dispatchGroup.leave()
                }.resume()
            }
        }
        
        dispatchGroup.wait()
        
        return downloadedSuccessfully()
    }
}
