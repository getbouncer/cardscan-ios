struct CardScanConfiguration {
    
    struct ModelDownload {
        let url: String
        let compiledName: String
    }
    
    static var findFourModelDownload: ModelDownload? = ModelDownload(url: "https://lab-fees.appspot.com/videos/FindFour.bin",
                                                                     compiledName: "FindFour.mlmodelc")
    static var fourRecognizeModelDownload: ModelDownload? = nil
    
    static func modelDownloadData() -> [ModelDownload] {
        return [findFourModelDownload, fourRecognizeModelDownload].compactMap() { $0 }
    }
}
