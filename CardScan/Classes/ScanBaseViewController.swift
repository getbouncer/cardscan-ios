import UIKit
import AVKit
import VideoToolbox
import Vision


@objc public protocol TestingImageDataSource {
    @objc func nextImage() -> CGImage?
}

@objc open class ScanBaseViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ScanEvents, AfterPermissions {
    
    public func onNumberRecognized(number: String, expiry: Expiry?, cardImage: CGImage, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?) {
        // relay this data to our own delegate object
        self.scanEventsDelegate?.onNumberRecognized(number: number, expiry: expiry, cardImage: cardImage, numberBoundingBox: numberBoundingBox, expiryBoundingBox: expiryBoundingBox)
    }
    
    public func onScanComplete(scanStats: ScanStats) {
        // this shouldn't get called
    }
    
    
    @objc public weak var testingImageDataSource: TestingImageDataSource?
    @objc public var errorCorrectionDuration = 1.5
    @objc public var includeCardImage = false
    @objc public var showDebugImageView = false
    
    public var scanEventsDelegate: ScanEvents?
    
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
    
    private var ocr = Ocr()
    
    // Child classes should override these three functions
    @objc open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) { }
    @objc open func showCardNumber(_ number: String, expiry: String?) { }
    @objc open func onCameraPermissionDenied(showedPrompt: Bool) { }
    
    public func toggleTorch() {
        self.ocr.scanStats.torchOn = !self.ocr.scanStats.torchOn
        self.videoFeed.toggleTorch()
    }
    
    @objc static public func configure(apiKey: String? = nil) {
        if let apiKey = apiKey {
            Api.apiKey = apiKey
        }
        
        self.machineLearningQueue.async {
            if #available(iOS 11.2, *) {
                registerAppNotifications()
                Ocr.configure()
            }
        }
    }
    
 
    // We're keeping track of the app's background state because we need to shut down
    // our ML threads, which use the GPU. Since there can be ML tasks in flight when
    // this happens our correctness criteria is:
    //   * For any new tasks, if we have `inBackground` set then we know that they
    //     won't hit the GPU
    //   * For any pending tasks, our sync block ensures that they finish before
    //     this returns
    //   * The willResignActive function blocks the transition to the background until
    //     it completes, which we couldn't find docs on but verified experimentally
    @objc static func willResignActive() {
        AppState.inBackground = true
        // this makes sure that any currently running predictions finish before we
        // let the app go into the background
        ScanViewController.machineLearningQueue.sync { }
    }
    
    @objc static func didBecomeActive() {
        AppState.inBackground = false
    }
    
    // Only call this function from the machineLearningQueue
    static func registerAppNotifications() {
        if hasRegisteredAppNotifications {
            return
        }
        
        hasRegisteredAppNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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
        let bundleUrl = Bundle(for: ScanViewController.self).url(forResource: "CardScan", withExtension: "bundle")!
        let bundle = Bundle(url: bundleUrl)!
        
        return UIImage(named: "camera", in: bundle, compatibleWith: nil)
    }
    
    public func cancelScan() {
        self.ocr.userCancelled()
        // fire and forget
        Api.scanStats(scanStats: self.ocr.scanStats, completion: {_, _ in })
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
        self.ocr.scanStats.permissionGranted = granted
        if !granted {
            self.onCameraPermissionDenied(showedPrompt: showedPrompt)
        }
    }
    
    // you must call setupOnViewDidLoad before calling this function and you have to call
    // this function to get the camera going
    public func startCameraPreview() {
        self.videoFeed.requestCameraAccess(permissionDelegate: self)
    }
    
    public func setupOnViewDidLoad(regionOfInterestLabel: UILabel, blurView: BlurView, previewView: PreviewView, cornerView: CornerView, debugImageView: UIImageView?) {
        
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

        //Apple example app sets up in viewDidLoad: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        self.videoFeed.setup(captureDelegate: self, completion: { success in })
  
        self.ocr.errorCorrectionDuration = self.errorCorrectionDuration

        // we split the implementation between OCR, which calls `onNumberRecognized`
        // and ScanBaseViewController, which calls `onScanComplete`. We register ourselves
        // as a delegate so that we can keep a single copy of the delegate object.
        self.ocr.scanEventsDelegate = self
        self.previewView?.videoPreviewLayer.session = self.videoFeed.session
        
        self.videoFeed.pauseSession()
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.ocr.numbers.removeAll()
        self.ocr.expiries.removeAll()
        self.ocr.firstResult = nil
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
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoFeed.willDisappear()
        
        if !self.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    public func getScanStats() -> ScanStats {
        return self.ocr.scanStats
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanViewController.machineLearningQueue.async {
                ScanBaseViewController.registerAppNotifications()
                self.captureOutputWork(sampleBuffer: sampleBuffer)
            }
        }
    }
    
    
    /* We're not ready for bardcodes again yet
    @available(iOS 11.0, *)
    func handleBarcodeResults(_ results: [Any]) {
        for result in results {
            // Cast the result to a barcode-observation
            
            if let barcode = result as? VNBarcodeObservation, barcode.symbology == .QR {
                
                if let payload = barcode.payloadStringValue {
                    DispatchQueue.main.async {
                        // XXX FIXME get QR Codes working again
                        if self.calledDelegate {
                            return
                        }
                        self.calledDelegate = true
                        self.scanDelegate?.userDidScanQrCode.map { $0(self, payload) }

                    }
                }
            }
        }
    }*/
    
    @available(iOS 11.2, *)
    func blockingQrModel(pixelBuffer: CVPixelBuffer) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInteractive).async {
            let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
                guard let _ = request.results else {
                    semaphore.signal()
                    return
                }
                // We took out QR code scanning for now
                //self.handleBarcodeResults(results)
                semaphore.signal()
            })

            let orientation = CGImagePropertyOrientation.up
            let requestOptions:[VNImageOption : Any] = [:]
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: orientation,
                                                options: requestOptions)
            guard let _ = try? handler.perform([barcodeRequest]) else {
                print("error with vision call for barcode")
                semaphore.signal()
                return
            }
        }
        semaphore.wait()
    }
    
    func drawBoundingBoxesOnImage(image: UIImage, embossedCharacterBoxes: [CGRect],
                                  characterBoxes: [CGRect], appleBoxes: [CGRect]) -> UIImage? {
        
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
        
        return newImage
    }
    
    @available(iOS 11.2, *)
    func blockingOcrModel(rawImage: CGImage) {
        let (number, expiry, done, foundNumberInThisScan) = ocr.performWithErrorCorrection(for: rawImage)
        if let number = number {
            self.showCardNumber(number, expiry: expiry?.display())
            if self.includeCardImage && foundNumberInThisScan {
                self.scannedCardImage = UIImage(cgImage: rawImage)
            }
        }
        
        if self.showDebugImageView {
            let flatBoxes = self.ocr.scanStats.lastFlatBoxes ?? []
            let embossedBoxes = self.ocr.scanStats.lastEmbossedBoxes ?? []
            let expiryBoxes = self.ocr.scanStats.expiryBoxes ?? []
            
            DispatchQueue.main.async {
                if self.debugImageView?.isHidden ?? false {
                    self.debugImageView?.isHidden = false
                }
                
                self.debugImageView?.image = self.drawBoundingBoxesOnImage(image: UIImage(cgImage: rawImage), embossedCharacterBoxes: embossedBoxes, characterBoxes: flatBoxes, appleBoxes: expiryBoxes)
            }
        }
        
        if done {
            DispatchQueue.main.async {
                guard let number = number else {
                    return
                }
                
                if self.calledOnScannedCard {
                    return
                }
                self.calledOnScannedCard = true
                
                ScanBaseViewController.machineLearningQueue.async {
                    // Note: the onNumberRecognized method is called on Ocr
                    self.scanEventsDelegate?.onScanComplete(scanStats: self.ocr.scanStats)
                }
                
                let expiryMonth = expiry.map { String($0.month) }
                let expiryYear = expiry.map { String($0.year) }
                let image = self.scannedCardImage
                
                // fire and forget
                Api.scanStats(scanStats: self.ocr.scanStats, completion: {_, _ in })
                self.onScannedCard(number: number, expiryYear: expiryYear, expiryMonth: expiryMonth, scannedImage: image)
            }
        }
    }
    
    func captureOutputWork(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("could not get the pixel buffer, dropping frame")
            self.machineLearningSemaphore.signal()
            return
        }
        
        guard let rawImage = self.toRegionOfInterest(pixelBuffer: pixelBuffer) else {
            print("could not get the cgImage from the region of interest, dropping frame")
            self.machineLearningSemaphore.signal()
            return
        }
        
        // we allow apps that integrate to supply their own sequence of images
        // for use in testing
        let image = self.testingImageDataSource?.nextImage() ?? rawImage
        
        if #available(iOS 11.2, *) {
            if self.scanQrCode {
                self.blockingQrModel(pixelBuffer: pixelBuffer)
            } else {
                self.blockingOcrModel(rawImage: image)
            }
        }
        
        self.machineLearningSemaphore.signal()
    }
    
    func toRegionOfInterest(pixelBuffer: CVPixelBuffer) -> CGImage? {
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
        
        guard let image = cgImage else {
            return nil
        }
        
        // use the full width
        let width = CGFloat(image.width)
        // keep the aspect ratio at 480:302
        let height = width * 302.0 / 480.0
        
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

        // convert from points to pixels and account for the cropped region
        if imageAspectRatio > screenAspectRatio {
            // left and right of the image cropped
            //      tested on: iPhone XS Max
            let croppedOffset = (CGFloat(image.width) - CGFloat(image.height) * screenAspectRatio) / 2.0
            let pointsToPixels = CGFloat(image.height) / screenHeight
            
            cx = regionOfInterestCenterX * pointsToPixels + croppedOffset
            cy = regionOfInterestCenterY * pointsToPixels
        } else {
            // top and bottom of the image cropped
            //      tested on: iPad Mini 2
            let croppedOffset = (CGFloat(image.height) - CGFloat(image.width) / screenAspectRatio) / 2.0
            let pointsToPixels = CGFloat(image.width) / screenWidth
            
            cx = regionOfInterestCenterX * pointsToPixels
            cy = regionOfInterestCenterY * pointsToPixels + croppedOffset
        }
        
        let rect = CGRect(x: cx - width / 2.0, y: cy - height / 2.0, width: width, height: height)
        
        self.currentImageRect = rect
        
        return image.cropping(to: rect)
    }
}
