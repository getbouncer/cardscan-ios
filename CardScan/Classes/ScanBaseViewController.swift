import UIKit
import AVKit
import VideoToolbox
import Vision
/**
 (3) scan stats
 (4) should use number stuff
 (5) make sure that testing still works
 (6) pull out unused stuff
 */

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
    static public let machineLearningQueue = DispatchQueue(label: "CardScanMlQueue")
    // Only access this variable from the machineLearningQueue
    static var hasRegisteredAppNotifications = false
    
    private weak var debugImageView: UIImageView?
    private weak var previewView: PreviewView?
    private weak var regionOfInterestLabel: UILabel?
    private weak var blurView: BlurView?
    private weak var cornerView: CornerView?
    private var regionOfInterestLabelFrame: CGRect?
    
    var videoFeed = VideoFeed()
    private let machineLearningSemaphore = DispatchSemaphore(value: 1)
    
    var currentImageRect: CGRect?
    var scannedCardImage: UIImage?
    var isNavigationBarHidden = false
    private let scanQrCode = false
    private let regionCornerRadius = CGFloat(10.0)
    private var calledOnScannedCard = false
    
    //private var ocr = Ocr()
    private var mainLoop = OcrMainLoop()
    // this is a hack to avoid changing our public interface
    var predictedName: String?
    
    // Child classes should override these three functions
    @objc open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) { }
    @objc open func showCardNumber(_ number: String, expiry: String?) { }
    @objc open func onCameraPermissionDenied(showedPrompt: Bool) { }
    @objc open func useCurrentFrameNumber(errorCorrectedNumber: String?, currentFrameNumber: String) -> Bool { return true }
    
    //MARK: -Torch Logic
    public func toggleTorch() {
        self.mainLoop.scanStats.torchOn = !self.mainLoop.scanStats.torchOn
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
        
        return UIInterfaceOrientationMask.portrait
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
            case "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone4,1", "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4", "iPhone6,1", "iPhone6,2", "iPhone7,2", "iPhone7,1":
                return false
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
        mainLoop.userCancelled()
        Api.scanStats(scanStats: self.mainLoop.scanStats, completion: {_, _ in })
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
        self.mainLoop.scanStats.permissionGranted = granted
        if !granted {
            self.onCameraPermissionDenied(showedPrompt: showedPrompt)
        }
    }
    
    // you must call setupOnViewDidLoad before calling this function and you have to call
    // this function to get the camera going
    public func startCameraPreview() {
        self.videoFeed.requestCameraAccess(permissionDelegate: self)
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
  
        self.mainLoop.mainLoopDelegate = self
        self.previewView?.videoPreviewLayer.session = self.videoFeed.session
        
        self.videoFeed.pauseSession()
        //Apple example app sets up in viewDidLoad: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        self.videoFeed.setup(captureDelegate: self, completion: { success in
            if let level = torchLevel {
                self.setTorchLevel(level: level)
            }
        })
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        ScanBaseViewController.isAppearing = true
        self.mainLoop.reset()
        self.calledOnScannedCard = false
        self.videoFeed.willAppear()
        self.isNavigationBarHidden = self.navigationController?.isNavigationBarHidden ?? true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let roiFrame = self.regionOfInterestLabel?.frame else { return }
         // store .frame to avoid accessing UI APIs in the machineLearningQueue
        self.regionOfInterestLabelFrame = roiFrame
        self.setUpCorners()
        self.setupMask()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.mainLoop.scanStats.orientation = UIWindow.interfaceOrientationToString
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
        return self.mainLoop.scanStats
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanBaseViewController.machineLearningQueue.async {
                self.captureOutputWork(sampleBuffer: sampleBuffer)
            }
        }
    }
    
    func captureOutputWork(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("could not get the pixel buffer, dropping frame")
            self.machineLearningSemaphore.signal()
            return
        }
        

        guard let fullCardImage = self.toCGImage(pixelBuffer: pixelBuffer) else {
            print("could not get the cgImage from the pixel buffer")
            self.machineLearningSemaphore.signal()
            return
        }
        
        guard let (squareCardImage, roiRectInPixels) = self.toRegionOfInterest(image: fullCardImage) else {
            print("could not get the cgImage from the region of interest, dropping frame")
            self.machineLearningSemaphore.signal()
            return
        }
        
        // we allow apps that integrate to supply their own sequence of images
        // for use in testing
        let (_, fullImage) = self.testingImageDataSource?.nextSquareAndFullImage() ?? (squareCardImage, fullCardImage)
        
        if #available(iOS 11.2, *) {
            mainLoop.push(fullImage: fullImage, roiRectangle: roiRectInPixels)
        }
        
        self.machineLearningSemaphore.signal()
    }
    
    func toCGImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
        var cgImage: CGImage?
        if #available(iOS 9.0, *) {
            #if swift(>=4.2)
                VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
            #else
                VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &cgImage)
            #endif
        } else {
            return nil
        }
        
        return cgImage
    }
    
    func toRegionOfInterest(image: CGImage) -> (CGImage, CGRect)? {
        // use the full width and make it a square
        let width = CGFloat(image.width)
        let height = width
        
        // get device screen size
        let screen = UIScreen.main.bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        guard let regionOfInterestLabelFrame = self.regionOfInterestLabelFrame else {
            return nil
        }
        
        // ROI center in Points
        let regionOfInterestCenterX = regionOfInterestLabelFrame.origin.x + regionOfInterestLabelFrame.size.width / 2.0
        
        let regionOfInterestCenterY = regionOfInterestLabelFrame.origin.y + regionOfInterestLabelFrame.size.height / 2.0
        
        // calculate center of cropping region in Pixels.
        var cx, cy: CGFloat
        
        
        // confirm videoGravity settings in previewView. Calculations based on .resizeAspectFill
        DispatchQueue.main.async {
            assert(self.previewView?.videoPreviewLayer.videoGravity == .resizeAspectFill)
        }

        // Find out whether left/right or top/bottom of the image was cropped before it was displayed to previewView.
        // The size of the cropped region is needed to map regionOfInterestCenter to the image center
        let imageAspectRatio = CGFloat(image.width) / CGFloat(image.height)
        let screenAspectRatio = screenWidth / screenHeight
        
        var pointsToPixels: CGFloat
        // convert from points to pixels and account for the cropped region
        if imageAspectRatio > screenAspectRatio {
            // left and right of the image cropped
            //      tested on: iPhone XS Max
            let croppedOffset = (CGFloat(image.width) - CGFloat(image.height) * screenAspectRatio) / 2.0
            pointsToPixels = CGFloat(image.height) / screenHeight
            
            cx = regionOfInterestCenterX * pointsToPixels + croppedOffset
            cy = regionOfInterestCenterY * pointsToPixels
        } else {
            // top and bottom of the image cropped
            //      tested on: iPad Mini 2
            let croppedOffset = (CGFloat(image.height) - CGFloat(image.width) / screenAspectRatio) / 2.0
            pointsToPixels = CGFloat(image.width) / screenWidth
            
            cx = regionOfInterestCenterX * pointsToPixels
            cy = regionOfInterestCenterY * pointsToPixels + croppedOffset
        }
        
        let roiWidthInPixels = regionOfInterestLabelFrame.size.width * pointsToPixels
        let roiHeightInPixels = regionOfInterestLabelFrame.size.height * pointsToPixels
        let roiRectInPixels = CGRect(x: cx - roiWidthInPixels * 0.5,
                                     y: cy - roiHeightInPixels * 0.5,
                                     width: roiWidthInPixels,
                                     height: roiHeightInPixels)
        
        let rect = CGRect(x: cx - width / 2.0, y: cy - height / 2.0, width: width, height: height)
        
        self.currentImageRect = rect
        
        return image.cropping(to: rect).map { ($0, roiRectInPixels) }
    }
    
    public func updateDebugImageView(image: UIImage) {
        self.debugImageView?.image = image
        if self.debugImageView?.isHidden ?? false {
            self.debugImageView?.isHidden = false
        }
    }
    
    // MARK: OcrMainLoopComplete logic
    func complete(creditCardOcrResult: CreditCardOcrResult) {
        self.dismiss(animated: true)
        mainLoop.mainLoopDelegate = nil
        ScanBaseViewController.machineLearningQueue.async {
            self.scanEventsDelegate?.onScanComplete(scanStats: self.mainLoop.scanStats)
        }
        
        let expiryMonth = creditCardOcrResult.expiryMonth
        let expiryYear = creditCardOcrResult.expiryYear
        let number = creditCardOcrResult.number
        // hack to work around having to change our public interface
        predictedName = creditCardOcrResult.name
        let image = self.scannedCardImage
        
        // fire and forget
        Api.scanStats(scanStats: self.mainLoop.scanStats, completion: {_, _ in })
        self.onScannedCard(number: number, expiryYear: expiryYear, expiryMonth: expiryMonth, scannedImage: image)
    }
    
    func prediction(creditCardOcrPrediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage) {
        if self.showDebugImageView {
            let numberBoxes = creditCardOcrPrediction.numberBoxes.map { $0.map { (UIColor.blue, $0) }} ?? []
            let expiryBoxes = creditCardOcrPrediction.expiryBoxes.map { $0.map { (UIColor.red, $0) }} ?? []
            let nameBoxes = creditCardOcrPrediction.nameBoxes.map { $0.map { (UIColor.green, $0) }} ?? []
            
            if self.debugImageView?.isHidden ?? false {
                self.debugImageView?.isHidden = false
            }
                
            self.debugImageView?.image = creditCardOcrPrediction.image.drawBoundingBoxesOnImage(boxes: numberBoxes + expiryBoxes + nameBoxes)
        }
        if creditCardOcrPrediction.number != nil && self.includeCardImage {
            self.scannedCardImage = UIImage(cgImage: creditCardOcrPrediction.image)
        }
        
        let cardSize = CGSize(width: creditCardOcrPrediction.image.width, height: creditCardOcrPrediction.image.height)
        if let number = creditCardOcrPrediction.number {
            let expiry: Expiry? = {
                if let month = creditCardOcrPrediction.expiryMonth.flatMap({ UInt($0) }),
                    let year = creditCardOcrPrediction.expiryYear.flatMap({ UInt($0) }),
                    let expiryString = creditCardOcrPrediction.expiryForDisplay {
                    return Expiry(string: expiryString, month: month, year: year)
                } else {
                    return nil
                }
            }()
            let xmin = creditCardOcrPrediction.numberBoxes?.map { $0.minX }.min() ?? 0.0
            let xmax = creditCardOcrPrediction.numberBoxes?.map { $0.maxX }.max() ?? 0.0
            let ymin = creditCardOcrPrediction.numberBoxes?.map { $0.minY }.min() ?? 0.0
            let ymax = creditCardOcrPrediction.numberBoxes?.map { $0.maxY }.max() ?? 0.0
            let numberBox = CGRect(x: xmin, y: ymin, width: (xmax - xmin), height: (ymax - ymin))
            let expiryBox = creditCardOcrPrediction.expiryBoxes.flatMap { $0.first }
            
            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onNumberRecognized(number: number, expiry: expiry, numberBoundingBox: numberBox, expiryBoundingBox: expiryBox, croppedCardSize: cardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
            }

        } else {
            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onFrameDetected(croppedCardSize: cardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
            }
        }
    }
    
    func showCardDetails(number: String?, expiry: String?, name: String?) {
        guard let number = number else { return }
        showCardNumber(number, expiry: expiry)
    }
}
