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
    public weak var stringDataSource: ScanStringsDataSource?
    public var allowSkip = false
    public var scanQrCode = false
    public var errorCorrectionDuration = 1.5
    
    static public let machineLearningQueue = DispatchQueue(label: "CardScanMlQueue")
    
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var blurView: UIView!
    
    @IBOutlet weak var scanCardLabel: UILabel!
    @IBOutlet weak var positionCardLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var regionOfInterestLabel: UILabel!
    @IBOutlet weak var regionOfInterestAspectConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var torchButton: UIButton!
    var videoFeed = VideoFeed()
    private let machineLearningSemaphore = DispatchSemaphore(value: 1)
    
    var currentImageRect: CGRect?
    
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
                Ocr.configure()
            }
        }
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
        if self.calledDelegate {
            return
        }
        self.ocr.userCancelled()
        self.calledDelegate = true
        self.scanDelegate?.userDidCancel(self)
    }
    
    @IBAction func skipButtonPress() {
        if self.calledDelegate {
            return
        }
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
        // these values are all copied from interface builder for setting
        // up the region of interest label. For some reason this value changes
        // as the screen sets up so we'll just hard code it here
        let x = CGFloat(16.0)
        let width = self.view.frame.width - 32.0
        let height = width * 226.0 / 359.0
        let y = self.view.frame.height * 0.5 - height * 0.5
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
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setStrings()
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
        self.videoFeed.setup(captureDelegate: self) { success in
            if success {
                self.setupMask()
            }
        }
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
        /*
        guard let imageRect = self.currentImageRect else {
            return
        }
        
        guard let numberRect = self.ocr.scanStats.numberRect else {
            return
        }*/
        
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
            
            /*
            let scaleX = self.view.frame.width / imageRect.width
            let scaleY = self.view.frame.height / (2.0 * (imageRect.minY + imageRect.height / 2.0))
            let numberHeight = numberRect.height * scaleY
            let numberWidth = numberRect.width * scaleX
            
            let numberX = (numberRect.minX + imageRect.minX) * scaleX
            let numberY = (numberRect.minY + imageRect.minY) * scaleY - numberHeight - 8.0
            
            let frameRect = CGRect(x: numberX, y: numberY, width: numberWidth, height: 50.0)
            
            let label = self.numberLabel ?? UILabel(frame: frameRect)
            label.frame = frameRect
            label.textAlignment = .center
            label.text = CreditCardUtils.format(number: number)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.1
            label.textColor = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
            label.font = label.font.withSize(60.0)

            if self.numberLabel == nil {
                self.numberLabel = label
                self.previewView.addSubview(label)
            }
            */
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanViewController.machineLearningQueue.async {
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
                    DispatchQueue.main.sync {
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
        let (number, expiry, done) = ocr.performWithErrorCorrection(for: rawImage)
        if let number = number {
            self.showCardNumber(number, expiry: expiry?.display())
        }
        
        if done {
            DispatchQueue.main.sync {
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
        
        // we're assuming that the preview frame is centered in the view, if it's not then
        // this calculation doesn't work. You'd need to grab references to the previewViewFrame
        // and the regionOfInterestFrame to figure it out
        
        // use the full width
        let width = Double(image.width)
        // keep the aspect ratio at 480:302
        let height = width * 302.0 / 480.0
        let cx = Double(image.width) / 2.0
        let cy = Double(image.height) / 2.0
        
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
