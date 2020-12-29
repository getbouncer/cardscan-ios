//
//  USScanCardViewController.swift
//  CardScan
//
//  Created by Valery Garaev on 29.12.2020.
//

import UIKit
import AVFoundation

@objc public protocol USScanCardDelegate {
    @objc func userDidPressManualEntry(_ scanViewController: USScanCardViewController)
    @objc func userDidCancel(_ scanViewController: USScanCardViewController)
    @objc func userDidScanCard(_ scanViewController: USScanCardViewController, creditCard: CreditCard)
}

open class USScanCardViewController: ScanBaseViewController {
    public var previewView: PreviewView = PreviewView()
    public var blurView: BlurView = BlurView()
    public var roiView: UIView = UIView()
    public var cornerView: CornerView?
    public var enableCameraPermissionsButton = UIButton(type: .system)
    public var enableCameraPermissionsText = UILabel()
    public var manualEntryButton = UIButton()
    
    // Dynamic card details
    public var numberText = UILabel()
    public var expiryText = UILabel()
    public var nameText = UILabel()
    public var expiryLayoutView = UIView()
    
    // String
    @objc public static var enableCameraPermissionString = "Разрешите доступ к камере"
    @objc public static var enableCameraPermissionsDescriptionString = "Для сканирования карты нужно внести изменения в настройках"
    
    public weak var delegate: USScanCardDelegate?
    
    public static func createViewController(returnButtonImage: UIImage, flashButtonImage: UIImage) -> USScanCardViewController {
        let vc = USScanCardViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.navigationController?.navigationBar.isTranslucent = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Наведите камеру на карту"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        vc.navigationItem.titleView = titleLabel
        
        let returnButton = UIButton()
        returnButton.setImage(returnButtonImage.withRenderingMode(.alwaysTemplate), for: .normal)
        returnButton.tintColor = .white
        returnButton.addTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: returnButton)
        
        if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
            let flashlightButton = UIButton()
            flashlightButton.setImage(flashButtonImage.withRenderingMode(.alwaysTemplate), for: .normal)
            flashlightButton.tintColor = .white
            flashlightButton.addTarget(self, action: #selector(didPressFlashButton), for: .touchUpInside)
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: flashlightButton)
        }
        
        return vc
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUiComponents()
        setupConstraints()
        
        setupOnViewDidLoad(
            regionOfInterestLabel: roiView,
            blurView: blurView,
            previewView: previewView,
            cornerView: cornerView,
            debugImageView: nil,
            torchLevel: 1.0
        )
        startCameraPreview()
    }
    
    // MARK: - Visual and UI event setup for UI components
    open func setupUiComponents() {
        view.backgroundColor = .white
        regionOfInterestCornerRadius = 15.0

        let subviews: [UIView] = [
            previewView,
            blurView,
            roiView,
            numberText,
            expiryText,
            nameText,
            expiryLayoutView,
            enableCameraPermissionsButton,
            enableCameraPermissionsText,
            manualEntryButton
        ]
        
        subviews.forEach { self.view.addSubview($0) }
        
        setupBlurViewUi()
        setupRoiViewUi()
        setupManualEntryButtonUi()
        setupCardDetailsUi()
        setupDenyUi()
    }
    
    open func setupManualEntryButtonUi() {
        manualEntryButton.setTitle("Ввести вручну", for: .normal)
        manualEntryButton.tintColor = .white
        manualEntryButton.setTitleColor(.white, for: .normal)
        manualEntryButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        manualEntryButton.addTarget(self, action: #selector(didPressManualEntry), for: .touchUpInside)
    }
    
    open func setupBlurViewUi() {
        blurView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0.8)
    }
    
    open func setupRoiViewUi() {
        roiView.layer.borderColor = UIColor.white.cgColor
    }
    
    open func setupCardDetailsUi() {
        numberText.isHidden = true
        numberText.textColor = .white
        numberText.textAlignment = .center
        numberText.font = numberText.font.withSize(48)
        numberText.adjustsFontSizeToFitWidth = true
        numberText.minimumScaleFactor = 0.2
        
        expiryText.isHidden = true
        expiryText.textColor = .white
        expiryText.textAlignment = .center
        expiryText.font = expiryText.font.withSize(20)
        
        nameText.isHidden = true
        nameText.textColor = .white
        nameText.font = expiryText.font.withSize(20)
    }
    
    open func setupDenyUi() {
        let text = USScanCardViewController.enableCameraPermissionString
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
        let font = enableCameraPermissionsButton.titleLabel?.font.withSize(20) ?? UIFont.systemFont(ofSize: 20.0)
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))
        enableCameraPermissionsButton.setAttributedTitle(attributedString, for: .normal)
        enableCameraPermissionsButton.isHidden = true
        
        enableCameraPermissionsButton.addTarget(self, action: #selector(enableCameraPermissionsPress), for: .touchUpInside)
        
        enableCameraPermissionsText.text = USScanCardViewController.enableCameraPermissionsDescriptionString
        enableCameraPermissionsText.textColor = .white
        enableCameraPermissionsText.textAlignment = .center
        enableCameraPermissionsText.font = enableCameraPermissionsText.font.withSize(17)
        enableCameraPermissionsText.numberOfLines = 3
        enableCameraPermissionsText.isHidden = true
    }
    
    // MARK: - Autolayout constraints
    open func setupConstraints() {
        let subviews: [UIView] = [
            previewView,
            blurView,
            roiView,
            numberText,
            expiryText,
            nameText,
            expiryLayoutView,
            enableCameraPermissionsButton,
            enableCameraPermissionsText,
            manualEntryButton
        ]
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        setupPreviewViewConstraints()
        setupBlurViewConstraints()
        setupRoiViewConstraints()
        setupManualEntryButtonConstraints()
        setupCardDetailsConstraints()
        setupDenyConstraints()
    }
    
    open func setupPreviewViewConstraints() {
        previewView.setAnchorsEqual(to: self.view)
    }
    
    open func setupBlurViewConstraints() {
        blurView.setAnchorsEqual(to: self.previewView)
    }
    
    open func setupRoiViewConstraints() {
        roiView.topAnchor.constraint(equalTo: view.topAnchor, constant: 128).isActive = true
        roiView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        roiView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        roiView.heightAnchor.constraint(equalToConstant: 210).isActive = true
    }
    
    private func setupManualEntryButtonConstraints() {
        manualEntryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 56).isActive = true
        manualEntryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    open func setupCardDetailsConstraints() {
        numberText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor, constant: 32).isActive = true
        numberText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor, constant: -32).isActive = true
        numberText.centerYAnchor.constraint(equalTo: roiView.centerYAnchor).isActive = true
        
        nameText.leadingAnchor.constraint(equalTo: numberText.leadingAnchor).isActive = true
        nameText.bottomAnchor.constraint(equalTo: roiView.bottomAnchor, constant: -16).isActive = true
        
        expiryLayoutView.topAnchor.constraint(equalTo: numberText.bottomAnchor).isActive = true
        expiryLayoutView.bottomAnchor.constraint(equalTo: nameText.topAnchor).isActive = true
        expiryLayoutView.leadingAnchor.constraint(equalTo: numberText.leadingAnchor).isActive = true
        expiryLayoutView.trailingAnchor.constraint(equalTo: numberText.trailingAnchor).isActive = true
        
        expiryText.leadingAnchor.constraint(equalTo: expiryLayoutView.leadingAnchor).isActive = true
        expiryText.trailingAnchor.constraint(equalTo: expiryLayoutView.trailingAnchor).isActive = true
        expiryText.centerYAnchor.constraint(equalTo: expiryLayoutView.centerYAnchor).isActive = true
    }
    
    open func setupDenyConstraints() {
        enableCameraPermissionsButton.topAnchor.constraint(equalTo: roiView.bottomAnchor, constant: 32).isActive = true
        enableCameraPermissionsButton.centerXAnchor.constraint(equalTo: roiView.centerXAnchor).isActive = true
        
        enableCameraPermissionsText.topAnchor.constraint(equalTo: enableCameraPermissionsButton.bottomAnchor, constant: 32).isActive = true
        enableCameraPermissionsText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor).isActive = true
        enableCameraPermissionsText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor).isActive = true
    }
    
    // MARK: - Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage
        
        delegate?.userDidScanCard(self, creditCard: card)
    }
    
    open func showScannedCardDetails(prediction: CreditCardOcrPrediction) {
        guard let number = prediction.number else {
            return
        }
                   
       numberText.text = CreditCardUtils.format(number: number)
       if numberText.isHidden {
           numberText.fadeIn()
       }
       
       if let expiry = prediction.expiryForDisplay {
           expiryText.text = expiry
           if expiryText.isHidden {
               expiryText.fadeIn()
           }
       }
       
       if let name = prediction.name {
           nameText.text = name
           if nameText.isHidden {
               nameText.fadeIn()
           }
       }
    }
    
    override open func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage, state: MainLoopState) {
        super.prediction(prediction: prediction, squareCardImage: squareCardImage, fullCardImage: fullCardImage, state: state)
        
        showScannedCardDetails(prediction: prediction)
    }
    
    override open func onCameraPermissionDenied(showedPrompt: Bool) {
        enableCameraPermissionsButton.isHidden = false
        enableCameraPermissionsText.isHidden = false
    }
    
    // MARK: - UI event handlers
    @objc open func cancelButtonPress() {
        delegate?.userDidCancel(self)
    }
    
    @objc open func didPressFlashButton() {
        toggleTorch()
    }
    
    @objc open func didPressManualEntry() {
        delegate?.userDidPressManualEntry(self)
    }
    
    /// Warning: if the user navigates to settings and updates the setting, it'll suspend your app.
    @objc open func enableCameraPermissionsPress() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
            print("can't open settings")
            return
        }
        
        UIApplication.shared.openURL(settingsUrl)
    }
}
