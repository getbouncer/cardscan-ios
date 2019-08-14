//
//  ScanCardViewController.swift
//  ScanCardFramework
//
//  Created by Sam King on 10/11/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import UIKit

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
    
    @objc public func expiryForDisplay() -> String? {
        guard var month = self.expiryMonth, var year = self.expiryYear else {
            return nil
        }
        
        if month.count == 1 {
            month = "0" + month
        }
        
        if year.count == 4 {
            year = String(year.suffix(2))
        }
        
        return "\(month)/\(year)"
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

@objc public class ScanViewController: ScanBaseViewController {
    
    public weak var scanDelegate: ScanDelegate?
    @objc public weak var stringDataSource: ScanStringsDataSource?
    @objc public var allowSkip = false
    public var scanQrCode = false
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
    
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var blurView: UIView!
    
    @IBOutlet weak var scanCardLabel: UILabel!
    @IBOutlet weak var positionCardLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonImageButton: UIButton!
    
    @IBOutlet weak var debugImageView: UIImageView!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var regionOfInterestLabel: UILabel!
    @IBOutlet weak var regionOfInterestAspectConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var torchButton: UIButton!
    
    var calledDelegate = false
    
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
    
    @IBAction func backTextPress() {
        self.backButtonPress("")
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        // Note: for the back button we may call the `userCancelled` delegate even if the
        // delegate has been called just as a safety precation to always provide the
        // user with a way to get out.
        self.cancelScan()
        self.calledDelegate = true
        self.scanDelegate?.userDidCancel(self)
    }
    
    @IBAction func skipButtonPress() {
        // Same for the skip button, like with the back button press we may call the
        // delegate function even if it's already been called
        self.cancelScan()
        self.calledDelegate = true
        self.scanDelegate?.userDidSkip(self)
    }

    @objc public func cancel(callDelegate: Bool) {
        if !self.calledDelegate {
            self.cancelScan()
            self.calledDelegate = true
        }
        
        if callDelegate {
            self.scanDelegate?.userDidCancel(self)
        }
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
        self.calledDelegate = false
        
        if self.allowSkip {
            self.skipButton.isHidden = false
        } else {
            self.skipButton.isHidden = true
        }
        
        let debugImageView = self.showDebugImageView ? self.debugImageView : nil
        self.setupOnViewDidLoad(regionOfInterestLabel: self.regionOfInterestLabel, blurView: self.blurView, previewView: self.previewView, debugImageView: debugImageView)
        self.startCameraPreview()
    }
    
    override public func showCardNumber(_ number: String, expiry: String?) {
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
    
    override public func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        
        if self.calledDelegate {
            return
        }
        
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
        
        self.calledDelegate = true
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.image = scannedImage

        self.scanDelegate?.userDidScanCard(self, creditCard: card)
    }
    
    
    @IBAction func toggleTorch(_ sender: Any) {
        self.toggleTorch()
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
