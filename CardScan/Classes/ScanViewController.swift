//
//  ScanCardViewController.swift
//  ScanCardFramework
//
//  Created by Sam King on 10/11/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import UIKit
//import AudioToolbox.AudioServices
import AVKit
import VideoToolbox
import Vision

#if canImport(Stripe)
    import Stripe
#endif


@objc public protocol ScanDelegate {
    @objc func userDidCancel(_ scanViewController: ScanViewController)
    @objc func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard)
    @objc optional func userDidScanQrCode(_ scanViewController: ScanViewController, payload: String)
    @objc func userDidSkip(_ scanViewController: ScanViewController)
}

@objc public protocol ScanStringsDataSource {
    @objc func scanCard() -> String
    @objc func positionCard() -> String
    @objc func backButton() -> String
    @objc func skipButton() -> String
}

@objc public class CreditCard: NSObject {
    @objc public var number: String
    @objc public var expiryMonth: String?
    @objc public var expiryYear: String?
    @objc public var name: String?
    @objc public var image: UIImage?
    
    public init(number: String) {
        self.number = number
    }
    
    #if canImport(Stripe)
    @objc public func cardParams() -> STPCardParams {
        let cardParam = STPCardParams()
        cardParam.number = self.number
        if let expiryMonth = self.expiryMonth, let expiryYear = self.expiryYear {
            cardParam.expYear = UInt(expiryYear) ?? 0
            cardParam.expMonth = UInt(expiryMonth) ?? 0
        }
        
        return cardParam
    }
    #endif
}

@objc public class ScanViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public weak var scanDelegate: ScanDelegate?
    @objc public weak var stringDataSource: ScanStringsDataSource?
    @objc public var allowSkip = false
    public var scanQrCode = false
    @objc public var errorCorrectionDuration = 1.5
    @objc public var includeCardImage = false
    @objc public var hideBackButtonImage = false
    @IBOutlet weak var backButtonImageToTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButtonWidthConstraint: NSLayoutConstraint!
    @objc public var backButtonImage: UIImage?
    @objc public var backButtonColor: UIColor?
    @objc public var backButtonFont: UIFont?
    @objc public var scanCardFont: UIFont?
    @objc public var positionCardFont: UIFont?
    @objc public var skipButtonFont: UIFont?
    @objc public var backButtonImageToTextDelta: NSNumber?
    
    static public let machineLearningQueue = DispatchQueue(label: "CardScanMlQueue")
    // Only access this variable from the machineLearningQueue
    static var hasRegisteredAppNotifications = false
    
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var blurView: UIView!
    
    @IBOutlet weak var scanCardLabel: UILabel!
    @IBOutlet weak var positionCardLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonImageButton: UIButton!
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var regionOfInterestLabel: UILabel!
    @IBOutlet weak var regionOfInterestAspectConstraint: NSLayoutConstraint!
    var regionOfInterestLabelFrame: CGRect?
    
    @IBOutlet weak var torchButton: UIButton!
    var videoFeed = VideoFeed()
    private let machineLearningSemaphore = DispatchSemaphore(value: 1)
    
    var currentImageRect: CGRect?
    var scannedCardImage: UIImage?
    
    var numberLabel: UILabel?
    var notMatchedCount = 0
    var isNavigationBarHidden = false
    
    var calledDelegate = false
    
    var ocr = Ocr()
    
    @objc static public func createViewController(withDelegate delegate: ScanDelegate? = nil) -> ScanViewController? {
        
        if !self.isCompatible() {
            return nil
        }
        
        let bundleUrl = Bundle(for: ScanViewController.self).url(forResource: "CardScan", withExtension: "bundle")!
        let bundle = Bundle(url: bundleUrl)!
        
        let storyboard = UIStoryboard(name: "CardScan", bundle: bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "scanCardViewController") as! ScanViewController
            viewController.scanDelegate = delegate
        return viewController
    }
    
    @objc static public func configure() {
        self.machineLearningQueue.async {
            if #available(iOS 11.0, *) {
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
        if #available(iOS 11.0, *) {
            return true
        } else {
            return false
        }
    }
    
    @objc static public func cameraImage() -> UIImage? {
        let bundleUrl = Bundle(for: ScanViewController.self).url(forResource: "CardScan", withExtension: "bundle")!
        let bundle = Bundle(url: bundleUrl)!
        
        return UIImage(named: "camera", in: bundle, compatibleWith: nil)
    }
    
    @IBAction func backTextPress() {
        self.backButtonPress("")
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        // Note: for the back button we may call the `userCancelled` delegate even if the
        // delegate has been called just as a safety precation to always provide the
        // user with a way to get out.
        self.ocr.userCancelled()
        self.calledDelegate = true
        self.scanDelegate?.userDidCancel(self)
    }
    
    @IBAction func skipButtonPress() {
        // Same for the skip button, like with the back button press we may call the
        // delegate function even if it's already been called
        self.ocr.userCancelled()
        self.calledDelegate = true
        self.scanDelegate?.userDidSkip(self)
    }

    @objc public func cancel(callDelegate: Bool) {
        if !self.calledDelegate {
            self.ocr.userCancelled()
            self.calledDelegate = true
        }

        if calledDelegate {
            self.scanDelegate?.userDidCancel(self)
        }
    }
    
    //jaime: added function to create blur mask
    let regionCornerRadius = CGFloat(10.0)
    func maskPreviewView(viewToMask: UIView, maskRect: CGRect) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        path.addRect(viewToMask.bounds)
        let roundedRectpath = UIBezierPath.init(roundedRect: maskRect, cornerRadius: regionCornerRadius).cgPath
        path.addPath(roundedRectpath)
        maskLayer.path = path
        #if swift(>=4.2)
            maskLayer.fillRule = .evenOdd
        #else
            maskLayer.fillRule = kCAFillRuleEvenOdd
        #endif
        viewToMask.layer.mask = maskLayer
    }
    
    func setupMask() {
        // store .frame to avoid accessing UI APIs in the machineLearningQueue
        self.regionOfInterestLabelFrame = self.regionOfInterestLabel.frame

        let regionOfInterestCenterY = self.regionOfInterestLabel.frame.origin.y + self.regionOfInterestLabel.frame.size.height / 2.0
        
        let x = regionOfInterestLabel.frame.origin.x
        let width = self.view.frame.width - (2.0 * x)
        let height = width * 226.0 / 359.0
        let y = regionOfInterestCenterY - height / 2.0
        
        let frame = CGRect(x: x, y: y, width: width, height: height)
        self.maskPreviewView(viewToMask: self.blurView, maskRect: frame)
        
        let cornerBorderWidth = CGFloat(5.0)
        let cornerRect = CGRect(x: frame.origin.x - cornerBorderWidth,
                                y: frame.origin.y - cornerBorderWidth,
                                width: frame.width + (2.0 * cornerBorderWidth),
                                height: frame.height + (2.0 * cornerBorderWidth))
        
        let cornersView = CornerView(frame: cornerRect)
        cornersView.layer.borderWidth = cornerBorderWidth
        cornersView.layer.cornerRadius = self.regionCornerRadius + cornerBorderWidth
        cornersView.layer.masksToBounds = true
        cornersView.backgroundColor = UIColor.clear
        cornersView.layer.borderColor = UIColor.green.cgColor
        
        cornersView.drawCorners(self.regionOfInterestLabel.layer.frame)
        self.previewView.addSubview(cornersView)
    }
    
    func setStrings() {
        guard let dataSource = self.stringDataSource else {
            return
        }
        
        self.scanCardLabel.text = dataSource.scanCard()
        self.positionCardLabel.text = dataSource.positionCard()
        self.skipButton.setTitle(dataSource.skipButton(), for: .normal)
        self.backButton.setTitle(dataSource.backButton(), for: .normal)
    }
    
    func setUiCustomization() {
        if self.hideBackButtonImage {
            self.backButtonImageButton.setImage(nil, for: .normal)
            // the image button is 8 from safe area and has a width of 32 the
            // label has a leading constraint of -11 so setting the width to
            // 19 sets the space from the safe region to 16
            self.backButtonWidthConstraint.constant = 19
        } else if let newImage = self.backButtonImage {
            self.backButtonImageButton.setImage(newImage, for: .normal)
        }
        
        if let color = self.backButtonColor {
            self.backButton.setTitleColor(color, for: .normal)
        }
        if let font = self.backButtonFont {
            self.backButton.titleLabel?.font = font
        }
        if let font = self.scanCardFont {
            self.scanCardLabel.font = font
        }
        if let font = self.positionCardFont {
            self.positionCardLabel.font = font
        }
        if let font = self.skipButtonFont {
            self.skipButton.titleLabel?.font = font
        }
        if let delta = self.backButtonImageToTextDelta.map({ CGFloat($0.floatValue) }) {
            self.backButtonImageToTextConstraint.constant += delta
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setStrings()
        self.setUiCustomization()
        setNeedsStatusBarAppearanceUpdate()
        
        if self.scanQrCode {
            self.regionOfInterestAspectConstraint.isActive = false
            if #available(iOS 9.0, *) {
                self.regionOfInterestLabel.heightAnchor.constraint(equalTo: self.regionOfInterestLabel.widthAnchor, multiplier: 1.0).isActive = true
                self.regionOfInterestLabel.heightAnchor.constraint(equalTo: self.regionOfInterestLabel.widthAnchor, multiplier: 1.0).isActive = true
            } else {
                // Fallback on earlier versions
            }
            self.regionOfInterestLabel.text = nil
            self.scanCardLabel.text = "Scan QR Code"
        }
        
        self.regionOfInterestLabel.layer.masksToBounds = true
        self.regionOfInterestLabel.layer.cornerRadius = self.regionCornerRadius
        self.regionOfInterestLabel.layer.borderColor = UIColor.white.cgColor
        self.regionOfInterestLabel.layer.borderWidth = 2.0
        self.calledDelegate = false
        
        if self.allowSkip {
            self.skipButton.isHidden = false
        } else {
            self.skipButton.isHidden = true
        }

        self.ocr.errorCorrectionDuration = self.errorCorrectionDuration
        
        self.videoFeed.requestCameraAccess()
        self.previewView.videoPreviewLayer.session = self.videoFeed.session
    }
    
    override public var shouldAutorotate: Bool {
        return false
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.videoFeed.setup(captureDelegate: self) { success in
            if success {
                self.setupMask()
            }
        }
        
        self.videoFeed.willAppear()
        self.isNavigationBarHidden = self.navigationController?.isNavigationBarHidden ?? true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        self.videoFeed.willDisappear()
        
        super.viewWillDisappear(animated)
        
        if !self.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    public func getScanStats() -> ScanStats {
        return self.ocr.scanStats
    }
    
    func showCardNumber(_ number: String, expiry: String?) {
        // we're assuming that the image takes up the full width and that
        // video has the same aspect ratio of the screen
        DispatchQueue.main.async {
            self.cardNumberLabel.text = CreditCardUtils.format(number: number)
            if self.cardNumberLabel.isHidden {
                self.cardNumberLabel.fadeIn()
            }
            
            if let expiry = expiry {
                self.expiryLabel.text = expiry
                if self.expiryLabel.isHidden {
                    self.expiryLabel.fadeIn()
                }
            }
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanViewController.machineLearningQueue.async {
                ScanViewController.registerAppNotifications()
                self.captureOutputWork(sampleBuffer: sampleBuffer)
            }
        }
    }
    
    @available(iOS 11.0, *)
    func handleBarcodeResults(_ results: [Any]) {
        for result in results {
            // Cast the result to a barcode-observation
            
            if let barcode = result as? VNBarcodeObservation, barcode.symbology == .QR {
                if let payload = barcode.payloadStringValue {
                    DispatchQueue.main.async {
                        if self.calledDelegate {
                            return
                        }
                        self.calledDelegate = true
                        self.scanDelegate?.userDidScanQrCode.map { $0(self, payload) }
                    }
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    func blockingQrModel(pixelBuffer: CVPixelBuffer) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInteractive).async {
            let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
                guard let results = request.results else {
                    semaphore.signal()
                    return
                }
                self.handleBarcodeResults(results)
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
    
    @available(iOS 11.0, *)
    func blockingOcrModel(rawImage: CGImage) {
        let (number, expiry, done, foundNumberInThisScan) = ocr.performWithErrorCorrection(for: rawImage)
        if let number = number {
            self.showCardNumber(number, expiry: expiry?.display())
            if self.includeCardImage && foundNumberInThisScan {
                self.scannedCardImage = UIImage(cgImage: rawImage)
            }
        }
        
        if done {
            DispatchQueue.main.async {
                guard let number = number else {
                    return
                }
                
                if self.calledDelegate {
                    return
                }
                
                let notification = UINotificationFeedbackGenerator()
                notification.prepare()
                notification.notificationOccurred(.success)
                //let vibrate = SystemSoundID(kSystemSoundID_Vibrate)
                //AudioServicesPlaySystemSound(vibrate)
                
                self.calledDelegate = true
                let card = CreditCard(number: number)
                card.expiryMonth = expiry.map { String($0.month) }
                card.expiryYear = expiry.map { String($0.year) }
                card.image = self.scannedCardImage
                self.scanDelegate?.userDidScanCard(self, creditCard: card)
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
        
        if #available(iOS 11.0, *) {
            if self.scanQrCode {
                self.blockingQrModel(pixelBuffer: pixelBuffer)
            } else {
                self.blockingOcrModel(rawImage: rawImage)
            }
        }
        
        self.machineLearningSemaphore.signal()
    }
    
    @IBAction func toggleTorch(_ sender: Any) {
        self.ocr.scanStats.torchOn = !self.ocr.scanStats.torchOn
        self.videoFeed.toggleTorch()
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
            assert(self.previewView.videoPreviewLayer.videoGravity == .resizeAspectFill)
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

// https://stackoverflow.com/a/53143736/947883
extension UIView {
    func fadeIn(_ duration: TimeInterval? = 0.4, onCompletion: (() -> Void)? = nil) {
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: duration!,
                       animations: { self.alpha = 1 },
                       completion: { (value: Bool) in
                        if let complete = onCompletion { complete() }})
    }
}
