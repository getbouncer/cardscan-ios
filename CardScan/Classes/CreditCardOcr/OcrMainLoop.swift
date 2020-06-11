/**
 This is the main loop for OCR. It runs one of our OCR systems in paralell with the Apple OCR system and
 combines results. From a high level this implements a standard producer-consumer where the main
 system will push images and ROI rectangles into the main loop and two Analyzers, or OCR systems
 will consume the images.

 The producer, which pushes images will keep N (2 currently) images in the queue and when a new image
 comes in it will remove old images leaving the N most recent images. That way we can try to get more
 diversity in images by virtue of maximizing the time in between images that it reads.

 The consumers pull images from the queue and run the full OCR algorithm, including expiry extraction and
 full error correction on the combined results.

 In terms of iOS abstractions, we make heavy use of dispatch queues. We have a single `mutexQueue`
 that we use to mutate our shared state. This queue is a serial queue and our method for synchronizing
 access. One thing to be careful with is we use `sync` in places to access our `mutexQueue`. This
 method can lead to deadlock if you aren't careful.

 We also have `machineLearningQueues` that we use to run each individual OCR algorithm.
 One important aspect of our `machineLearningQueues` is that we monitor when the app goes into
 the background and kill all ML before letting the app go into the background.

 # Correcness criteria
 We make heavy use of dispatch queues for paralellism, so it's important to be disciplined about how
 we access shared state

 ## Shared state
 All shared state updates need to happeon on the `mutexQueue`

 ## Delegate invocation
 All invocations of delegate methods need to happen on the main queue, and for each prediction there
 are one or more methods that may get called in order:
 - `prediction` this happens on all predictions
 - if the scan predicts a number, then `showCardDetails` happens with the current overall predicted number, expiry, and name
 - if the scan is complete, then `complete` includes the final result

 To finalize results, we clear out the `mainLoopDelegate` after it's done

 It's important that we not update `scanStats` after complete is called or call any futher delegate functions, although
 more predictions might come through after the fact

 We also expose `shouldUsePrediction` that delegates can implement to discard a prediction, but note that the `prediction`
 method still fires even when this returns false. Note: `shouldUsePrediction` is called from the `mutexQueue` so handlers
 don't need to synchronize but they may need to handle any computation that needs to happen on the main loop appropriately.
 
 ## userCancelled
 One aspect to be careful with when someone invokes the `userCancelled` method is that there could be a race with OCR and it
 could complete OCR in parallel with this call. The net result we want is if a caller calls this method we don't subsequenty fire any of
 the `OcrMainLoopDelegate` methods and we want to make sure that `scanStats.success` is always `false` to correctly
 denote that this scan failed.
  
 To handle this correctly we:
 - use the `userDidCancel` variable here and in any of our blocks that run on the main dispatch queue. Since this call should
 come from the main dispatch queue, those calls, where we invoke the callback methods, will run after this one and we prevent firing
 their delegate methods.
 - the logic to set `scanStats.success` will come on the `muxtexQueue`, but could execute either before or after this block runs.
    - If it's before then this block will overwrite the `success` results with the unsuccessful result here. If the
    - If it runs after, there is a check and it sets `scanStats.success` iff it isn't already set
 - we use `sync` on the `muxtexQueue` to make sure that when this method returns any subsequent calls to `scanStats` are
 always `success = false`
 */

import UIKit

public protocol OcrMainLoopDelegate: class {
    func complete(creditCardOcrResult: CreditCardOcrResult)
    func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage)
    func showCardDetails(number: String?, expiry: String?, name: String?)
    func shouldUsePrediction(errorCorrectedNumber: String?, prediction: CreditCardOcrPrediction) -> Bool
}

public protocol MachineLearningLoop: class {
    func push(fullImage: CGImage, roiRectangle: CGRect)
}

public class OcrMainLoop : MachineLearningLoop {
    public enum AnalyzerType {
        case apple
        case legacy
        case ssd
    }
    
    public var scanStats = ScanStats()
    
    public weak var mainLoopDelegate: OcrMainLoopDelegate?
    var errorCorrection = ErrorCorrection()
    var imageQueue: [(CGImage, CGRect)] = []
    public var imageQueueSize = 2
    var analyzerQueue: [CreditCardOcrImplementation] = []
    let mutexQueue = DispatchQueue(label: "OcrMainLoopMuxtex")
    var inBackground = false
    var machineLearningQueues: [DispatchQueue] = []
    var userDidCancel = false
    
    public init(analyzers: [AnalyzerType] = [.ssd, .apple]) {
        scanStats.model = "ssd+apple"
        machineLearningQueues = []
        for analyzer in analyzers {
            let queue = DispatchQueue(label: "\(analyzer) OCR ML")
            switch (analyzer) {
            case .ssd:
                if #available(iOS 11.2, *) {
                    analyzerQueue.append(SSDCreditCardOcr(dispatchQueue: queue))
                }
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
                let _ = mainLoop
                let _ = ocr.recognizeCard(in: cgImage, roiRectangle: roiRectangle)
            }
        }
    }
    
    // see the Correctness Criteria note in the comments above for why this is correct
    // Make sure you call this from the main dispatch queue
    func userCancelled() {
        userDidCancel = true
        mutexQueue.sync { [weak self] in
            guard let self = self else { return }
            if self.scanStats.success == nil {
                self.scanStats.success = false
                self.scanStats.endTime = Date()
                self.mainLoopDelegate = nil
            }
        }
    }
    
    public func push(fullImage: CGImage, roiRectangle: CGRect) {
        mutexQueue.sync {
            guard !inBackground else { return }
            // only keep the latest images
            imageQueue.insert((fullImage, roiRectangle), at: 0)
            while imageQueue.count > imageQueueSize {
                let _ = imageQueue.popLast()
            }
            
            // if we have any analyzers waiting, fire them off now
            guard let ocr = analyzerQueue.popLast() else { return }
            analyzer(ocr: ocr)
        }
    }

    func postAnalyzerToQueueAndRun(ocr: CreditCardOcrImplementation) {
        mutexQueue.async { [weak self] in
            guard let self = self else { return }
            self.analyzerQueue.insert(ocr, at: 0)
            // only kick off the next analyzer if there is an image in the queue
            if self.imageQueue.count > 0 {
                guard let ocr = self.analyzerQueue.popLast() else { return }
                self.analyzer(ocr: ocr)
            }
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
                self.scanStats.scans += 1
                let delegate = self.mainLoopDelegate
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard !self.userDidCancel else { return }
                    guard let squareCardImage = CreditCardOcrImplementation.squareCardImage(fullCardImage: image, roiRectangle: roi) else { return }
                    delegate?.prediction(prediction: prediction, squareCardImage: squareCardImage, fullCardImage: image)
                }
                guard let result = self.combine(prediction: prediction), result.isFinished else {
                    self.postAnalyzerToQueueAndRun(ocr: ocr)
                    return
                }
            }
        }
    }
    
    func combine(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        guard mainLoopDelegate?.shouldUsePrediction(errorCorrectedNumber: errorCorrection.number, prediction: prediction) ?? true else { return nil }
        guard let result = errorCorrection.add(prediction: prediction) else { return nil }
        let delegate = mainLoopDelegate
        if result.isFinished && scanStats.success == nil {
            scanStats.success = true
            scanStats.endTime = Date()
            mainLoopDelegate = nil
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.userDidCancel else { return }
            delegate?.showCardDetails(number: result.number, expiry: result.expiry, name: result.name)
            if result.isFinished {
                delegate?.complete(creditCardOcrResult: result)
            }
        }
        return result
    }
    
    // MARK: -backrounding logic
    
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
        mutexQueue.sync { self.inBackground = true }
        // this makes sure that any currently running predictions finish before we
        // let the app go into the background
        for queue in machineLearningQueues {
            queue.sync {
                queue.suspend()
            }
        }
    }
    
    @objc func didBecomeActive() {
        // isBackground is true only when the queues are suspended.
        // isBackground flag is used as a proxy areQueuesSuspended flag to avoid crash
        mutexQueue.sync {
            if self.inBackground {
                for queue in machineLearningQueues {
                    queue.resume()
                }
            }
            self.inBackground = false
        }
    }
    
    // Only call this function from the machineLearningQueue
    func registerAppNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func unregisterAppNotifications() {
        // if we're in the background resume our queues so that we can free them but leave `inBackground` set so that they don't run
        mutexQueue.sync {
            if self.inBackground {
                machineLearningQueues.forEach { $0.resume() }
            }
        }
        NotificationCenter.default.removeObserver(self)
    }
}
