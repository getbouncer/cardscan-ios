import UIKit
import AVFoundation
import Vision

import CardScan

struct TestStats {
    var scans = 0
    var duration = 0.0
    var correct = 0
    var incorrect = 0
    var notDetected = 0
    var expiryCorrect = 0
    var expiryIncorrect = 0
    var expiryNotDetected = 0
    var binCheckCorrect = 0
    var binCheckIncorrect = 0
    var binDuration = 0.0
    var card = ""
    
    func binsChecked() -> Int {
        return self.binCheckCorrect + self.binCheckIncorrect
    }
}

class ViewController: UIViewController {
    var videoData: [[String: String]] = []
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var debugImageView: UIImageView!
    let videoQueue = DispatchQueue(label: "videos")
    let ocrQueue = DispatchQueue(label: "ocr")

    let dispatchGroup = DispatchGroup()
    var overallCorrect = 0
    var overall = 0
    var unknownCardNumbers: [String: Int] = [:]
    
    var ocr: CreditCardOcrImplementation?
    
    var currentNumber = ""
    var currentExpiry = ""
    var currentTestResult: TestStats?
    
    let baseUrl = "https://lab-fees.appspot.com/videos/"
    
    var testResults: [TestStats] = []
    
    // will block, run in a dispatchqueue
    func cacheVideos() {
        let session = URLSession(configuration: .ephemeral)
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        
        let testDir = documentDirectory.appendingPathComponent("test")
        if !FileManager.default.fileExists(atPath: testDir.path) {
            try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: false, attributes: nil)
        }
        
        let dispatchGroup = DispatchGroup()
        
        for data in videoData {
            let destinationFile = documentDirectory.appendingPathComponent(data["name"]!)
            if !FileManager.default.fileExists(atPath: destinationFile.path) {
                let url = URL(string: "\(self.baseUrl)\(data["name"]!)")!
                dispatchGroup.enter()
                session.downloadTask(with: url) { (location: URL?, response: URLResponse?, error: Error?) in
                    guard let location = location else {
                        dispatchGroup.leave()
                        print("could not download file")
                        return
                    }
                    print("saving file")
                    try! FileManager.default.moveItem(at: location, to: destinationFile)
                    dispatchGroup.leave()
                }.resume()
            }
        }
        
        dispatchGroup.wait()
    }
    
    func processVideo(fileUrl: URL, card: String?) {
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: AVAsset(url: fileUrl))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        let rawTimes = stride(from: 0.25, to: 5.0, by: 0.25).map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 600)) }
        
        for _ in rawTimes {
            self.dispatchGroup.enter()
        }
        
        self.ocrQueue.sync {
            self.currentTestResult = TestStats()
        }
        generator.generateCGImagesAsynchronously(forTimes: rawTimes, completionHandler: self.handleImage)
        
        self.dispatchGroup.wait()
        
        self.ocrQueue.sync {
            self.currentTestResult?.card = card ?? "unknown"
            self.currentTestResult.map { self.testResults.append($0) }
            self.currentTestResult = TestStats()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "videos", withExtension: "json")
        let jsonData = try! Data(contentsOf: url!)
        videoData = try! JSONSerialization.jsonObject(with: jsonData) as! [[String : String]]
        
        videoQueue.async {
            self.cacheVideos()
        }
        
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        for data in videoData {
            videoQueue.async {
                let url = documentDirectory.appendingPathComponent(data["name"]!)
                self.currentNumber = data["number"]!
                self.currentExpiry = data["expiry"]!
                self.processVideo(fileUrl: url, card: data["card"])
            }
        }
        
        videoQueue.async {
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultsViewController
                vc.results = self.testResults
                self.present(vc, animated: true)
            }
        }
    }

    func drawBoundingBoxesOnImage(image: UIImage, embossedCharacterBoxes: [CGRect],
                                  characterBoxes: [CGRect], appleBoxes: [CGRect]) -> UIImage {
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint(x: 0,y :0))

        UIGraphicsGetCurrentContext()?.setLineWidth(3.0)
        
        UIColor.green.setStroke()
        for characterBox in characterBoxes {
            UIRectFrame(characterBox)
        }
        
        UIColor.blue.setStroke()
        for characterBox in embossedCharacterBoxes {
            UIRectFrame(characterBox)
        }
        
        UIColor.red.setStroke()
        for characterBox in appleBoxes {
            UIRectFrame(characterBox)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func postBackgroundTrainingDigits(image: CGImage, boxes: [CGRect]) {
        var dxs: [CGFloat] = []
        for idx in 0..<(boxes.count-1) {
            dxs.append(0.5 * (boxes[idx+1].minX - boxes[idx].minX))
        }
        
        var offsetBoxes: [CGRect] = []
        for (idx, dx) in dxs.enumerated() {
            let box = boxes[idx]
            let rect = CGRect(x: box.origin.x + dx,
                              y: box.origin.y,
                              width: box.size.width,
                              height: box.size.height)
            offsetBoxes.append(rect)
        }
        
        let imageStrings = offsetBoxes.compactMap { UIImage(cgImage: image.cropping(to: $0)!).pngData()?.base64EncodedString() }
        let digits = imageStrings.map { ["image_png": $0, "label": "10"] }
        Api.trainingEmbossedDigits(imagesAndLabels: digits)
    }
    
    func postTrainingImages(image: CGImage, boxes: [CGRect]) {
        let imageStrings = boxes.compactMap { UIImage(cgImage: image.cropping(to: $0)!).pngData()?.base64EncodedString() }
        let images = imageStrings.map { ["image_png": $0] }
        Api.trainingImages(images: images)
    }
    
    func postTrainingDigits(image: CGImage, boxes: [CGRect]) {
        let imageStrings = boxes.compactMap { UIImage(cgImage: image.cropping(to: $0)!).pngData()?.base64EncodedString() }
        
        /*
        var sampledImageStrings: [String] = []
        for _ in 0..<self.currentNumber.count {
            sampledImageStrings.append(imageStrings[Int.random(in: 0..<imageStrings.count)])
        }*/
        
        let embossedDigits = zip(imageStrings, self.currentNumber).map { ["image_png": $0, "label": String($1)] }
        Api.trainingEmbossedDigits(imagesAndLabels: embossedDigits)
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        
        UIGraphicsBeginImageContext(CGSize(width: 480, height: 302))
        image.draw(in: CGRect(x: 0, y: 0,
                              width: 480,
                              height: 302))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func postDetectionImage(image: CGImage) {
        let imageData = self.resizeImage(image: UIImage(cgImage: image)).pngData()!.base64EncodedString()
        Api.trainingDetectionImage(imagePng: imageData)
    }
    
    func cardScanOcr(fullImage: CGImage, roiRectangle: CGRect) {
        let startTime = Date()
        guard let ocr = ocr else { preconditionFailure() }
        let prediction = ocr.recognizeCard(in: fullImage, roiRectangle: roiRectangle)
        let number = prediction.number
        self.currentTestResult?.scans += 1
        self.currentTestResult?.duration -= startTime.timeIntervalSinceNow
        if number == nil {
            self.currentTestResult?.notDetected += 1
        } else if number == self.currentNumber {
            self.currentTestResult?.correct += 1
        } else {
            //self.postTrainingImages(image: ccImage, boxes: (ocr.scanStats.lastFlatBoxes ?? []))
            self.currentTestResult?.incorrect += 1
            print("Incorrect scan \(number!) != \(self.currentNumber)")
        }
        
        let expiry = prediction.expiryForDisplay.map { expiryString in
            return expiryString.filter { $0 != "/" }
        }
        if expiry == nil {
            self.currentTestResult?.expiryNotDetected += 1
        } else if expiry == self.currentExpiry {
            self.currentTestResult?.expiryCorrect += 1
        } else {
            self.currentTestResult?.expiryIncorrect += 1
            print("expiry incorrect \(expiry!) != \(self.currentExpiry)")
        }
        
        DispatchQueue.main.async {
            let result = number ?? "None"
            self.unknownCardNumbers[result] = (self.unknownCardNumbers[result] ?? 0) + 1
        }
    
        DispatchQueue.main.sync {
            // TODO: add the boxes back in
            let flatBoxes = prediction.numberBoxes ?? []
            //let embossedBoxes = ocr.scanStats.lastEmbossedBoxes ?? []
            //let expiryBoxes = ocr.scanStats.expiryBoxes ?? []
            let embossedBoxes: [CGRect] = prediction.nameBoxes ?? []
            let expiryBoxes: [CGRect] = prediction.expiryBoxes ?? []
            let croppedImage = fullImage.croppedImageForSsd(roiRectangle: roiRectangle)!
            
            self.imageView.image = self.drawBoundingBoxesOnImage(image: UIImage(cgImage: croppedImage), embossedCharacterBoxes: embossedBoxes, characterBoxes: flatBoxes, appleBoxes: expiryBoxes)
        }
    }
    
    func handleImage(requestedTime: CMTime, image: CGImage?, actualTime: CMTime, result: AVAssetImageGenerator.Result, error: Error?) -> Void {
       
        guard let image = image else {
            return
        }

        // use the full width
        let width = Double(image.width)
        // keep the aspect ratio at 480:302
        let height = 375.0 * width / 600.0
        let cx = Double(image.width) / 2.0
        let cy = Double(image.height) / 2.0
        
        let rect = CGRect(x: cx - width / 2.0, y: cy - height / 2.0, width: width, height: height)
        self.ocrQueue.async {
            self.cardScanOcr(fullImage: image, roiRectangle: rect)
            self.dispatchGroup.leave()
        }
    }
}
