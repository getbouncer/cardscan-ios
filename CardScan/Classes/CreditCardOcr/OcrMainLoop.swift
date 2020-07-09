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
 All shared state updates need to happeon on the `mutexQueue` except for `machineLearningQueue`,
 which we set at the constructor and access it read only.

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
 
 ## Backgrounding and ML
 Our ML algorithms use the GPU and can cause crashes when we run them in the background. Thus, we track the app's
 backgrounding state and stop any ML tasks (analyzers) before the app reaches the background.
 - Each analyzer has it's own dispatch queue. Within that dispatch queue we pop an image off of the image queue
    - if the image queue is empty or the the app is in the background the closure will exit without running any ML
    - If the closure is running ML, we add an empty `sync` block on the ML queue while we're backgrounding that will block until it's finished
        - After the `sync` call finishes, since there are no images and `isBackground` is set, subsequent invocations of the ML will stop without running any GPU workloads
    - The analyzers restart after the app leaves the background and the camera starts pushing new images
 
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

open class OcrMainLoop : MachineLearningLoop {
    public enum AnalyzerType {
        case apple
        case ssd
    }
    
    public var scanStats = ScanStats()
    
    public weak var mainLoopDelegate: OcrMainLoopDelegate?
    public var errorCorrection = ErrorCorrection()
    var imageQueue: [(CGImage, CGRect)] = []
    public var imageQueueSize = 2
    var analyzerQueue: [CreditCardOcrImplementation] = []
    let mutexQueue = DispatchQueue(label: "OcrMainLoopMuxtex")
    var inBackground = false
    var machineLearningQueues: [DispatchQueue] = []
    var userDidCancel = false
    
    public init(analyzers: [AnalyzerType] = [.ssd, .apple]) {
        var ocrImplementations: [CreditCardOcrImplementation] = []
        for analyzer in analyzers {
            let queue = DispatchQueue(label: "\(analyzer) OCR ML")
            switch (analyzer) {
            case .ssd:
                if #available(iOS 11.2, *) {
                    ocrImplementations.append(SSDCreditCardOcr(dispatchQueue: queue))
                }
            case .apple:
                if #available(iOS 13.0, *) {
                    ocrImplementations.append(AppleCreditCardOcr(dispatchQueue: queue))
                }
            }
        }
        setupMl(ocrImplementations: ocrImplementations)
    }
    
    /// Note: you must call this function in your constructor
    public func setupMl(ocrImplementations: [CreditCardOcrImplementation]) {
        machineLearningQueues = []
        scanStats.model = "ssd+apple"
        for ocrImplementation in ocrImplementations {
            machineLearningQueues.append(ocrImplementation.dispatchQueue)
            analyzerQueue.append(ocrImplementation)
        }
        registerAppNotifications()
    }
    
    func reset() {
        mutexQueue.async {
            self.errorCorrection = self.errorCorrection.reset()
        }
    }
    
    static func warmUp() {
        let mainLoop = OcrMainLoop()
        let image = UIImage.grayImage(size: CGSize(width: 600, height: 600))
        let roiRectangle = CGRect(x: 0, y: 0, width: 600, height: 600)
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
        // make sure that no new images get pushed to our image buffer
        // and we clear out the image buffer
        mutexQueue.sync {
            self.inBackground = true
            self.imageQueue = []
        }
        
        // make sure that all current prediction finishes. New invocations will block since
        // the queue is empty and inBackground is set
        // Note: it's important to call this outside of the mutexQueue to avoid deadlock
        for queue in self.machineLearningQueues {
            queue.sync { }
        }
    }
    
    @objc func didBecomeActive() {
        mutexQueue.sync {
            self.inBackground = false
            self.errorCorrection = self.errorCorrection.reset()
        }
    }
    
    func registerAppNotifications() {
        // We don't need to unregister these functions because the system will clean
        // them up for us
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
