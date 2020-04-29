import Vision
import UIKit

@available(iOS 13.0, *)
struct AppleOcr {
    static func configure() {
        // warm up the model eventually
    }
    
    static func convertToImageRect(boundingBox: VNRectangleObservation?, imageSize: CGSize) -> CGRect {
        guard let boundingBox = boundingBox else {
            return CGRect()
        }

        let topLeft = VNImagePointForNormalizedPoint(boundingBox.bottomLeft,
                                                     Int(imageSize.width),
                                                     Int(imageSize.height))
        let bottomRight = VNImagePointForNormalizedPoint(boundingBox.topRight,
                                                         Int(imageSize.width),
                                                         Int(imageSize.height))
        // flip it for top left (0,0) image coordinates
        return CGRect(x: topLeft.x, y: topLeft.y,
                      width: abs(bottomRight.x - topLeft.x),
                      height: abs(topLeft.y - bottomRight.y))
        
    }
    
    static func performOcr(image: CGImage, completion: @escaping ([OcrObject]) -> Void) {
        let textRequest = VNRecognizeTextRequest() { request, error in
            let imageSize = CGSize(width: image.width, height: image.height)
            var outputObjects: [OcrObject] = []
            if let results = request.results, !results.isEmpty {
                if let results = request.results as? [VNRecognizedTextObservation] {
                    for result in results {
                        if let candidate = result.topCandidates(1).first {
                            let string = candidate.string
                            let box = try? candidate.boundingBox(for: string.startIndex..<string.endIndex)
                            let boxRect = convertToImageRect(boundingBox: box.flatMap({ $0 }), imageSize: imageSize)
                            let confidence: Float = 1.0
                            outputObjects.append(OcrObject(text: string, conf: confidence,
                                                           textBox: boxRect,
                                                           imageSize: imageSize))
                        }
                    }
                }
            }
            
            completion(outputObjects)
        }
       
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = false
       
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            completion([])
        }
    }
    
    static func recognizeText(in image: CGImage, complete: @escaping ([OcrObject]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            performOcr(image: image) { complete($0) }
        }
    }
}
