import UIKit
import AVKit
import Vision

public protocol TestingImageDataSource: AnyObject {
    func nextSquareAndFullImage() -> (CGImage, CGImage)?
}

@objc open class ScanBaseViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AfterPermissions, OcrMainLoopDelegate {
    
    public weak var testingImageDataSource: TestingImageDataSource?
    @objc public var errorCorrectionDuration = 1.5
    @objc public var includeCardImage = false
    @objc public var showDebugImageView = false
    
    public var scanEventsDelegate: ScanEvents?
    
    static var isAppearing = false
    static var isPadAndFormsheet: Bool = false
    static public let machineLearningQueue = DispatchQueue(label: "CardScanMlQueue")
    private let machineLearningSemaphore = DispatchSemaphore(value: 1)
    
    private weak var debugImageView: UIImageView?
    private weak var previewView: PreviewView?
    private weak var regionOfInterestLabel: UILabel?
    private weak var blurView: BlurView?
    private weak var cornerView: CornerView?
    private var regionOfInterestLabelFrame: CGRect?
    private var previewViewFrame: CGRect?
    
    var videoFeed = VideoFeed()

    var scannedCardImage: UIImage?
    var isNavigationBarHidden = false
    private let regionCornerRadius = CGFloat(10.0)
    private var calledOnScannedCard = false
    
    public var mainLoop: MachineLearningLoop? = OcrMainLoop()
    private func ocrMainLoop() -> OcrMainLoop? {
        return mainLoop.flatMap { $0 as? OcrMainLoop }
    }
    // this is a hack to avoid changing our public interface
    var predictedName: String?
    
    // Child classes should override these three functions
    @objc open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) { }
    @objc open func showCardNumber(_ number: String, expiry: String?) { }
    @objc open func onCameraPermissionDenied(showedPrompt: Bool) { }
    @objc open func useCurrentFrameNumber(errorCorrectedNumber: String?, currentFrameNumber: String) -> Bool { return true }
    
    //MARK: -Torch Logic
    public func toggleTorch() {
        self.ocrMainLoop()?.scanStats.torchOn = !(self.ocrMainLoop()?.scanStats.torchOn ?? false)
        self.videoFeed.toggleTorch()
    }
    
    public func isTorchOn() -> Bool{
        return self.videoFeed.isTorchOn()
    }
    
    public func hasTorchAndIsAvailable() -> Bool {
        return self.videoFeed.hasTorchAndIsAvailable()
    }
        
    public func setTorchLevel(level: Float) {
        if 0.0...1.0 ~= level {
            self.videoFeed.setTorchLevel(level: level)
        } else {
            print("Not a valid torch level")
        }
    }
    
    @objc static public func configure(apiKey: String? = nil) {
        if let apiKey = apiKey {
            Api.apiKey = apiKey
        }
        
        self.machineLearningQueue.async {
            if #available(iOS 11.2, *) {
                //Ocr.configure()
                OcrMainLoop.warmUp()
            }
        }
    }
    
    @objc public static func supportedOrientationMaskOrDefault() -> UIInterfaceOrientationMask {
        guard ScanBaseViewController.isAppearing else {
            // If the ScanBaseViewController isn't appearing then fall back
            // to getting the orientation mask from the infoDictionary, just like
            // the system would do if the user didn't override the
            // supportedInterfaceOrientationsFor method
            let supportedOrientations = (Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String]) ?? ["UIInterfaceOrientationPortrait"]
            
            let maskArray = supportedOrientations.map { option -> UIInterfaceOrientationMask in
                switch (option) {
                case "UIInterfaceOrientationPortrait":
                    return UIInterfaceOrientationMask.portrait
                case "UIInterfaceOrientationPortraitUpsideDown":
                    return UIInterfaceOrientationMask.portraitUpsideDown
                case "UIInterfaceOrientationLandscapeLeft":
                    return UIInterfaceOrientationMask.landscapeLeft
                case "UIInterfaceOrientationLandscapeRight":
                    return UIInterfaceOrientationMask.landscapeRight
                default:
                    return UIInterfaceOrientationMask.portrait
                }
            }
            
            let mask: UIInterfaceOrientationMask = maskArray.reduce(UIInterfaceOrientationMask.portrait) { result, element in
                return UIInterfaceOrientationMask(rawValue: result.rawValue | element.rawValue)
            }
            
            return mask
        }
        return ScanBaseViewController.isPadAndFormsheet ? .allButUpsideDown : .portrait
    }
    
    @objc static public func isCompatible() -> Bool {
        return self.isCompatible(configuration: ScanConfiguration())
    }
    
    @objc static public func isCompatible(configuration: ScanConfiguration) -> Bool {
        // check to see if the user has already denined camera permission
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus != .authorized && authorizationStatus != .notDetermined && configuration.setPreviouslyDeniedDevicesAsIncompatible {
            return false
        }
        
        if #available(iOS 11.2, *) {
            // make sure that we don't run on iPhone 6 / 6plus or older
            if configuration.runOnOldDevices {
                return true
            }
            switch Api.deviceType() {
                case "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone4,1":
                    return true
                case "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4", "iPhone6,1", "iPhone6,2", "iPhone7,2", "iPhone7,1":
                    return true
                default:
                    return true
            }
        } else {
            return false
        }
    }
    
    @objc static public func cameraImage() -> UIImage? {
        guard let bundle = CSBundle.bundle() else {
            return nil
        }
        
        return UIImage(named: "camera", in: bundle, compatibleWith: nil)
    }
    
    public func cancelScan() {
        guard let ocrMainLoop = ocrMainLoop()  else {
            return
        }
        ocrMainLoop.userCancelled()
        Api.scanStats(scanStats: ocrMainLoop.scanStats, completion: {_, _ in })
    }
     
    func setupMask() {
        guard let roi = self.regionOfInterestLabel else { return }
        guard let blurView = self.blurView else { return }
        blurView.maskToRoi(roi: roi)
    }
    
    public func setUpCorners() {
        guard let roi = self.regionOfInterestLabel else { return }
        guard let corners = self.cornerView else { return }
        corners.setFrameSize(roi: roi)
        corners.drawCorners()
    }

    func permissionDidComplete(granted: Bool, showedPrompt: Bool) {
        self.ocrMainLoop()?.scanStats.permissionGranted = granted
        if !granted {
            self.onCameraPermissionDenied(showedPrompt: showedPrompt)
        }
    }
    
    // you must call setupOnViewDidLoad before calling this function and you have to call
    // this function to get the camera going
    public func startCameraPreview() {
        self.videoFeed.requestCameraAccess(permissionDelegate: self)
    }
    
    func setVideoOrientation() {
        if ScanBaseViewController.isPadAndFormsheet {
            self.previewView?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIWindow.interfaceOrientation.rawValue)
            self.videoFeed.videoOrientation = self.previewView?.videoOrientation
        } else {
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
            self.previewView?.videoOrientation = .portrait
            self.videoFeed.videoOrientation = .portrait
        }
    }
    
    public func setupOnViewDidLoad(regionOfInterestLabel: UILabel, blurView: BlurView, previewView: PreviewView, cornerView: CornerView, debugImageView: UIImageView?, torchLevel: Float?) {
        
        self.regionOfInterestLabel = regionOfInterestLabel
        self.blurView = blurView
        self.previewView = previewView
        self.debugImageView = debugImageView
        self.cornerView = cornerView
        
        setNeedsStatusBarAppearanceUpdate()
        regionOfInterestLabel.layer.masksToBounds = true
        regionOfInterestLabel.layer.cornerRadius = self.regionCornerRadius
        regionOfInterestLabel.layer.borderColor = UIColor.white.cgColor
        regionOfInterestLabel.layer.borderWidth = 2.0
  
        self.ocrMainLoop()?.mainLoopDelegate = self
        self.previewView?.videoPreviewLayer.session = self.videoFeed.session
        ScanBaseViewController.isPadAndFormsheet = UIDevice.current.userInterfaceIdiom == .pad && self.modalPresentationStyle == .formSheet
        
        self.setVideoOrientation()
        
        if testingImageDataSource != nil {
            self.ocrMainLoop()?.imageQueueSize = 20
        }
        
        self.videoFeed.pauseSession()
        //Apple example app sets up in viewDidLoad: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        self.videoFeed.setup(captureDelegate: self, completion: { success in
            if let level = torchLevel {
                self.setTorchLevel(level: level)
            }
        })
    }
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return ScanBaseViewController.isPadAndFormsheet ? .allButUpsideDown : .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return ScanBaseViewController.isPadAndFormsheet ? UIWindow.interfaceOrientation : .portrait
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoFeedConnection = self.videoFeed.videoDeviceConnection {
            self.previewView?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)
            videoFeedConnection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) ?? .portrait
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScanBaseViewController.isAppearing = true
        self.ocrMainLoop()?.reset()
        self.calledOnScannedCard = false
        self.videoFeed.willAppear()
        self.isNavigationBarHidden = self.navigationController?.isNavigationBarHidden ?? true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let roiFrame = self.regionOfInterestLabel?.frame, let previewViewFrame = self.previewView?.frame else { return }
         // store .frame to avoid accessing UI APIs in the machineLearningQueue
        self.regionOfInterestLabelFrame = roiFrame
        self.previewViewFrame = previewViewFrame
        self.setUpCorners()
        self.setupMask()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.ocrMainLoop()?.scanStats.orientation = UIWindow.interfaceOrientationToString
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoFeed.willDisappear()
        
        if !self.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ScanBaseViewController.isAppearing = false
    }
    
    public func getScanStats() -> ScanStats {
        return self.ocrMainLoop()?.scanStats ?? ScanStats()
    }
    
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanBaseViewController.machineLearningQueue.async {
                self.captureOutputWork(sampleBuffer: sampleBuffer)
                self.machineLearningSemaphore.signal()
            }
        }
    }

    func captureOutputWork(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("could not get the pixel buffer, dropping frame")
            return
        }
        

        guard let fullCameraImage = pixelBuffer.cgImage() else {
            print("could not get the cgImage from the pixel buffer")
            return
        }
        
        // confirm videoGravity settings in previewView. Calculations based on .resizeAspectFill
        DispatchQueue.main.async {
            assert(self.previewView?.videoPreviewLayer.videoGravity == .resizeAspectFill)
        }
        
        guard let roiFrame = self.regionOfInterestLabelFrame, let previewViewFrame = self.previewViewFrame,
        let (fullScreenImage, roiRectInPixels) = fullCameraImage.toFullScreenAndRoi(previewViewFrame: previewViewFrame, regionOfInterestLabelFrame: roiFrame) else {
            print("could not get the cgImage from the region of interest, dropping frame")
            return
        }
        
        // we allow apps that integrate to supply their own sequence of images
        // for use in testing
        if let dataSource = self.testingImageDataSource {
            guard let (_, fullTestingImage) = dataSource.nextSquareAndFullImage() else {
                return
            }
            mainLoop?.push(fullImage: fullTestingImage, roiRectangle: roiRectInPixels)
        } else {
            if #available(iOS 11.2, *) {
                mainLoop?.push(fullImage: fullScreenImage, roiRectangle: roiRectInPixels)
            }
        }
    }
    
    public func updateDebugImageView(image: UIImage) {
        self.debugImageView?.image = image
        if self.debugImageView?.isHidden ?? false {
            self.debugImageView?.isHidden = false
        }
    }
    
    // MARK: -OcrMainLoopComplete logic
    public func complete(creditCardOcrResult: CreditCardOcrResult) {
        ocrMainLoop()?.mainLoopDelegate = nil
        ScanBaseViewController.machineLearningQueue.async {
            self.scanEventsDelegate?.onScanComplete(scanStats: self.getScanStats())
        }
        
        // hack to work around having to change our public interface
        predictedName = creditCardOcrResult.name

        // fire and forget
        Api.scanStats(scanStats: self.getScanStats(), completion: {_, _ in })
        self.onScannedCard(number: creditCardOcrResult.number, expiryYear: creditCardOcrResult.expiryYear, expiryMonth: creditCardOcrResult.expiryMonth, scannedImage: scannedCardImage)
    }
    
    public func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage) {
        if self.showDebugImageView {
            let numberBoxes = prediction.numberBoxes?.map { (UIColor.blue, $0) } ?? []
            let expiryBoxes = prediction.expiryBoxes?.map { (UIColor.red, $0) } ?? []
            let nameBoxes = prediction.nameBoxes?.map { (UIColor.green, $0) } ?? []
            
            if self.debugImageView?.isHidden ?? false {
                self.debugImageView?.isHidden = false
            }
                
            self.debugImageView?.image = prediction.image.drawBoundingBoxesOnImage(boxes: numberBoxes + expiryBoxes + nameBoxes)
        }
        if prediction.number != nil && self.includeCardImage {
            self.scannedCardImage = UIImage(cgImage: prediction.image)
        }
        
        let cardSize = CGSize(width: prediction.image.width, height: prediction.image.height)
        if let number = prediction.number, let numberBox = prediction.numberBox {
            let expiry = prediction.expiryObject()
            let expiryBox = prediction.expiryBox
            
            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onNumberRecognized(number: number, expiry: expiry, numberBoundingBox: numberBox, expiryBoundingBox: expiryBox, croppedCardSize: cardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
            }
        } else {
            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onFrameDetected(croppedCardSize: cardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
            }
        }
    }
    
    public func showCardDetails(number: String?, expiry: String?, name: String?) {
        guard let number = number else { return }
        showCardNumber(number, expiry: expiry)
    }
    
    public func shouldUsePrediction(errorCorrectedNumber: String?, prediction: CreditCardOcrPrediction) -> Bool {
        guard let predictedNumber = prediction.number else { return true }
        return useCurrentFrameNumber(errorCorrectedNumber: errorCorrectedNumber, currentFrameNumber: predictedNumber)
    }
}
