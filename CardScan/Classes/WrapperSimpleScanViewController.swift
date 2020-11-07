//
//  WrapperSimpleScanViewController.swift
//  CardScan
//
//  Created by Jaime Park on 11/6/20.
//
import UIKit
import Foundation

@available(iOS 11.2, *)
@objc public class WrapperSimpleScanViewController: SimpleScanViewController {

    @objc public var blurViewBackgroundColor: UIColor?
    @objc public var roiViewBorderColor: UIColor?
    
    @objc public var descriptionTextUILabel: UILabel?
    @objc public var closeUIButton: UIButton?
    @objc public var torchUIButton: UIButton?
    @objc public var enableCameraPermissionsUILabel: UILabel?
    @objc public var enableCameraPermissionsUIButton: UIButton?
    
    @objc public var cardNumberTextColor: UIColor?
    @objc public var cardExpiryTextColor: UIColor?
    @objc public var cardNameTextColor: UIColor?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    //MARK: Background UI
    override public func setupBlurViewUi() {
        super.setupBlurViewUi()
        if let blurViewBackgroundColor = blurViewBackgroundColor {
            blurView.backgroundColor = blurViewBackgroundColor
        }
    }
    
    override public func setupRoiViewUi() {
        super.setupRoiViewUi()
        if let roiViewBorderColor = roiViewBorderColor {
            roiView.layer.borderColor = roiViewBorderColor.cgColor
        }
    }
    
    //MARK: View Controller Detail UI
    override public func setupDescriptionTextUi() {
        super.setupDescriptionTextUi()
        if let descriptionTextUILabel = descriptionTextUILabel {
            descriptionText.text = descriptionTextUILabel.text
            descriptionText.font = descriptionTextUILabel.font
            descriptionText.textColor = descriptionTextUILabel.textColor
            descriptionText.textAlignment = descriptionTextUILabel.textAlignment
        }
    }
    
    override public func setupCloseButtonUi() {
        super.setupCloseButtonUi()
        if let closeUIButton = closeUIButton {
            closeButton.setTitle(closeUIButton.titleLabel?.text, for: .normal)
            closeButton.setTitleColor(closeUIButton.titleLabel?.textColor, for: .normal)
            closeButton.titleLabel?.font = closeUIButton.titleLabel?.font
        }
        
        if let closeUIButtonImage = closeUIButton?.image(for: .normal) {
            closeButton.setImage(closeUIButtonImage, for: .normal)
        }
    }
    
    override public func setupTorchButtonUi() {
        super.setupTorchButtonUi()
        if let torchUIButton = torchUIButton {
            torchButton.setTitle(torchUIButton.titleLabel?.text, for: .normal)
            torchButton.setTitleColor(torchUIButton.titleLabel?.textColor, for: .normal)
            torchButton.titleLabel?.font = torchUIButton.titleLabel?.font
        }
        
        if let torchUIButtonImage = torchUIButton?.image(for: .normal) {
            torchButton.setImage(torchUIButtonImage, for: .normal)
        }
    }
    
    override public func setupDenyUi() {
        super.setupDenyUi()
        if let enableButton = enableCameraPermissionsUIButton {
            let text = enableButton.titleLabel?.text ?? "Enable Camera Access"
            let font = enableButton.titleLabel?.font.withSize(20) ?? UIFont.systemFont(ofSize: 20.0)
            
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: enableButton.titleLabel?.textColor ?? UIColor.white, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: enableButton.titleLabel?.textColor ?? UIColor.white, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))

            enableCameraPermissionsButton.setAttributedTitle(attributedString, for: .normal)
        }
        
        if let enableUIButtonImage = enableCameraPermissionsUIButton?.image(for: .normal) {
            enableCameraPermissionsButton.setImage(enableUIButtonImage, for: .normal)
        }
        
        if let enableLabel = enableCameraPermissionsUILabel {
            enableCameraPermissionsText.text = enableLabel.text
            enableCameraPermissionsText.font = enableLabel.font
            enableCameraPermissionsText.textColor = enableLabel.textColor
            enableCameraPermissionsText.textAlignment = enableLabel.textAlignment
        }
    }
    
    //MARK: Card Detail UI
    override public func setupCardDetailsUi() {
        super.setupCardDetailsUi()
        if let cardNumberTextColor = cardNumberTextColor {
            numberText.textColor = cardNumberTextColor
        }
        
        if let cardExpiryTextColor = cardExpiryTextColor {
            expiryText.textColor = cardExpiryTextColor
        }
        
        if let nameTextColor = cardNameTextColor {
            nameText.textColor = nameTextColor
        }
    }
    
    @objc public static func createWrapperSimpleViewController() -> WrapperSimpleScanViewController {
        let vc = WrapperSimpleScanViewController()

        if UIDevice.current.userInterfaceIdiom == .pad {
           // For the iPad you can use the full screen style but you have to select "requires full screen" in
           // the Info.plist to lock it in portrait mode. For iPads, we recommend using a formSheet, which
           // handles all orientations correctly.
            vc.modalPresentationStyle = .formSheet
        } else {
            vc.modalPresentationStyle = .fullScreen
        }

        return vc
    }
}

