//
//  OcrMainLoop.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

/**
    This is the main loop for OCR. It runs one of our OCR systems in paralell with the Apple OCR system and
    combines results. From a high level this implements a standard producer-consumer where the main
    system will push images and ROI rectangles into the main loop and two Analyzers, or OCR systems
    will consume the images.
 
    The producer, which pushes images will keep N (2 currently) images in the queue and when a new image
    comes in it will remove old images leaving the N most recent images. That way we can try to get more
    diversity in images by virtue of maximizing the time in between images that it reads.
 
    The consumers pull images from the queue and run the full OCR algorithm, including expiry extraction and
    full error correction independently.
 
    In terms of iOS abstractions, we make heavy use of dispatch queues. We have a single `mutexQueue`
    that we use to mutate our shared state. This queue is a serial queue and our method for synchronizing
    access. One thing to be careful with is we use `sync` in places to access our `mutexQueue`. This
    method can lead to deadlock if you aren't careful.
 
    We also have N `machineLearningQueues` that we define statically and use to run
    each individual OCR algorithm. One important aspect of our `machineLearningQueues` is that we
    monitor when the app goes into the background and kill all ML before letting the app go into the background.
 
    The main items left TODO are:
    - Combine the results from each OCR run. Our OCR runs have three states, (1) no pan detected, (2) pan
        detected but running error correction and (3) complete results. After an OCR run is complete, it stops
        reading images.
    - Pass the results back to the ViewController that registers with the `OcrMainLoopComplete`
        protocol to let it know when to start showing or update number / expiry via the
        `showCardDetails` method and notify the ViewController when it is all done using the `complete`
        method.
 */

import UIKit

protocol OcrMainLoopDelegate: class {
    func complete(creditCardOcrResult: CreditCardOcrResult)
    func prediction(creditCardOcrPrediction: CreditCardOcrPrediction)
    func showCardDetails(number: String?, expiry: String?, name: String?)
}

class OcrMainLoop {
    enum AnalyzerType {
        case apple
        case legacy
    }
    
    var scanStats = ScanStats()
    
    weak var mainLoopDelegate: OcrMainLoopDelegate?
    var errorCorrection = ErrorCorrection()
    var imageQueue: [(CGImage, CGRect)] = []
    var analyzerQueue: [CreditCardOcrImplementation] = []
    let mutexQueue = DispatchQueue(label: "OcrMainLoopMuxtex")
    var inBackground = false
    var machineLearningQueues: [DispatchQueue] = []
    
    init(analyzers: [AnalyzerType] = [.legacy, .apple]) {
        machineLearningQueues = []
        for analyzer in analyzers {
            let queue = DispatchQueue(label: "\(analyzer) OCR ML")
            switch (analyzer) {
            case .legacy:
                if #available(iOS 11.2, *) {
                    analyzerQueue.append(LegacyCreditCardOcr(dispatchQueue: queue))
                }
            case .apple:
                if #available(iOS 13.0, *) {
                    analyzerQueue.append(AppleCreditCardOcr(dispatchQueue: queue))
                }
            }
            machineLearningQueues.append(queue)
        }
        registerAppNotifications()
    }
    
    deinit {
        unregisterAppNotifications()
    }
    
    func reset() {
        mutexQueue.async {
            self.errorCorrection = ErrorCorrection()
        }
    }
    
    static func warmUp() {
        let mainLoop = OcrMainLoop()
        let image = UIImage.grayImage(size: CGSize(width: 500, height: 500))
        let roiRectangle = CGRect(x: 0, y: 0, width: 500, height: 500)
        guard let cgImage = image?.cgImage else { return }
        for ocr in mainLoop.analyzerQueue {
            ocr.dispatchQueue.async {
                let _ = ocr.recognizeCard(in: cgImage, roiRectangle: roiRectangle)
            }
        }
    }
    
    func userCancelled() {
        scanStats.success = false
        scanStats.endTime = Date()
    }
    
    func push(fullImage: CGImage, roiRectangle: CGRect) {
        mutexQueue.sync {
            guard !inBackground else { return }
            // only keep the latest images
            imageQueue.insert((fullImage, roiRectangle), at: 0)
            while imageQueue.count > 2 {
                let _ = imageQueue.popLast()
            }
            
            // if we have any analyzers waiting, fire them off now
            guard let ocr = analyzerQueue.popLast() else { return }
            analyzer(ocr: ocr)
        }
    }

    func postAnalyzerToQueueAndRun(ocr: CreditCardOcrImplementation) {
        mutexQueue.async { [weak self] in
            self?.analyzerQueue.insert(ocr, at: 0)
            guard let ocr = self?.analyzerQueue.popLast() else { return }
            self?.analyzer(ocr: ocr)
        }
    }
    
    func analyzer(ocr: CreditCardOcrImplementation) {
        ocr.dispatchQueue.async { [weak self] in
            var fullImage: CGImage?
            var roiRectangle: CGRect?
            
            // grab an image and roi from the image queue. If the image queue is empty then add ourselves
            // back to the analyzer queue
            self?.mutexQueue.sync {
                guard !(self?.inBackground ?? false) else {
                    self?.analyzerQueue.insert(ocr, at: 0)
                    return
                }
                guard let (fullImageFromQueue, roiRectangleFromQueue) = self?.imageQueue.popLast() else {
                    self?.analyzerQueue.insert(ocr, at: 0)
                    return
                }
                fullImage = fullImageFromQueue
                roiRectangle = roiRectangleFromQueue
            }
            
            guard let image = fullImage, let roi = roiRectangle else { return }
            
            // run our ML model, add ourselves back to the analyzer queue unless we have a result
            // and the result is finished
            let prediction = ocr.recognizeCard(in: image, roiRectangle: roi)
            self?.mutexQueue.async {
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.mainLoopDelegate?.prediction(creditCardOcrPrediction: prediction)
                }
                guard let result = self.combine(prediction: prediction), result.isFinished else {
                    self.postAnalyzerToQueueAndRun(ocr: ocr)
                    return
                }
            }
        }
    }
    
    func combine(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        guard let result = errorCorrection.add(prediction: prediction) else { return nil }
        DispatchQueue.main.async { [weak self] in
            self?.mainLoopDelegate?.showCardDetails(number: result.number, expiry: result.expiry, name: result.name)
            if result.isFinished {
                self?.mainLoopDelegate?.complete(creditCardOcrResult: result)
            }
        }
        return result
    }
    
    func blockingOcr(fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrResult? {
        var result: CreditCardOcrResult?
        mutexQueue.sync {
            guard let analyzer = analyzerQueue.first else { return }
            let prediction = analyzer.recognizeCard(in: fullImage, roiRectangle: roiRectangle)
            result = errorCorrection.add(prediction: prediction)
        }
        
        return result
    }
    
    // MARK: backrounding logic
    
    // We're keeping track of the app's background state because we need to shut down
    // our ML threads, which use the GPU. Since there can be ML tasks in flight when
    // this happens our correctness criteria is:
    //   * For any new tasks, if we have `inBackground` set then we know that they
    //     won't hit the GPU
    //   * For any pending tasks, our sync block ensures that they finish before
    //     this returns
    //   * The willResignActive function blocks the transition to the background until
    //     it completes, which we couldn't find docs on but verified experimentally
    @objc func willResignActive() {
        print("clean up ML, entering background")
        inBackground = true
        // this makes sure that any currently running predictions finish before we
        // let the app go into the background
        for queue in machineLearningQueues {
            queue.sync {
                queue.suspend()
            }
        }
    }
    
    @objc func didBecomeActive() {
        print("leaving background, fire up queues again")
        inBackground = false
        for queue in machineLearningQueues {
            queue.resume()
        }
    }
    
    // Only call this function from the machineLearningQueue
    func registerAppNotifications() {
        print("registerAppNotifications")
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func unregisterAppNotifications() {
        print("unregisterAppNotifications")
        NotificationCenter.default.removeObserver(self)
    }
}
