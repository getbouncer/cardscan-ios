//
//  ViewController.swift
//  CardScan
//
//  Created by Sam King on 10/15/2018.
//  Copyright (c) 2018 Sam King. All rights reserved.
//
import AVFoundation
import UIKit
import CardScan

class ViewController: UIViewController, ScanEvents, ScanDelegate, FullScanStringsDataSource, TestingImageDataSource {

    let testImages = [UIImage(imageLiteralResourceName: "frame0"),
                      UIImage(imageLiteralResourceName: "frame19"),
                      UIImage(imageLiteralResourceName: "frame38"),
                      UIImage(imageLiteralResourceName: "frame57"),
                      UIImage(imageLiteralResourceName: "frame73"),
                      UIImage(imageLiteralResourceName: "frame76"),
                      UIImage(imageLiteralResourceName: "frame95"),
                      UIImage(imageLiteralResourceName: "frame99"),
                      UIImage(imageLiteralResourceName: "frame114"),
                      UIImage(imageLiteralResourceName: "frame133")]
    
    var currentTestImages: [CGImage]?
    
    func nextSquareAndFullImage() -> (CGImage, CGImage)? {
        if self.currentTestImages?.first == nil {
            self.currentTestImages = self.testImages.compactMap { $0.cgImage }
        }
        
        guard let fullCardImage = self.currentTestImages?.first else {
            print("could not get full size test image")
            return nil
        }
        
        let squareCropImage = fullCardImage
        let width = CGFloat(squareCropImage.width)
        let height = width
        let x = CGFloat(0) 
        let y = CGFloat(squareCropImage.height) * 0.5 - height * 0.5
        
        guard let squareCardImage = squareCropImage.cropping(to: CGRect(x: x, y: y, width: width, height: height)) else {
            print("could not crop test image")
            return nil
        }
    
        self.currentTestImages = self.currentTestImages?.dropFirst().map { $0 }
        return (squareCardImage, fullCardImage)
    }
    
    func scanCard() -> String { return "New Scan Card" }
    func positionCard() -> String { return "New Position Card" }
    func backButton() -> String { return "New Back" }
    func skipButton() -> String { return "New Skip" }
    func denyPermissionTitle() -> String { return "New Deny" }
    func denyPermissionMessage() -> String { return "New Deny Message" }
    func denyPermissionButton() -> String { return "GO" }
    
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultViewController
        vc.scanStats = scanViewController.getScanStats()
        vc.number = creditCard.number
        vc.cardImage = creditCard.image
        vc.expiration = creditCard.expiryForDisplay()
        vc.name = creditCard.name
        
        self.dismiss(animated: true)
        self.present(vc, animated: true)
    }

    func userDidScanQrCode(_ scanViewController: ScanViewController, payload: String) {
        self.dismiss(animated: true)
        print(payload)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraImage.image = ScanViewController.cameraImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !ScanViewController.isCompatible() {
            self.scanCardButton.isHidden = true
        }
    }
    
    func onNumberRecognized(number: String, expiry: Expiry?, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?, croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?) {}
    func onScanComplete(scanStats: ScanStats) {}
    func onFrameDetected(croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?) {}
    
    @IBOutlet weak var cameraImage: UIImageView!
    @IBOutlet weak var scanCardButton: UIButton!
    
    @IBAction func scanQrCodePress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.scanQrCode = true
        self.present(vc, animated: true)
    }
    @IBAction func scanCardPress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        
        self.present(vc, animated: true)
    }
    
    @IBAction func scanCardOldDevicePress() {
        let config = ScanConfiguration()
        config.runOnOldDevices = true
        guard let vc = ScanViewController.createViewController(withDelegate: self, configuration: config) else {
            print("scan view controller not supported on this hardware")
            return
        }
        
        vc.allowSkip = true
        self.present(vc, animated: true)
    }
    
    @IBAction func scanCardCustomStringsPress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.allowSkip = true
        vc.stringDataSource = self
        
        vc.backButtonColor = UIColor.red
        vc.hideBackButtonImage = true
        vc.backButtonImageToTextDelta = 8.0
        
        vc.backButtonFont = UIFont(name: "Verdana", size: CGFloat(17.0))
        vc.scanCardFont = UIFont(name: "Chalkduster", size: CGFloat(24.0))
        vc.positionCardFont = UIFont(name: "Chalkduster", size: CGFloat(17.0))
        vc.skipButtonFont = UIFont(name: "Chalkduster", size: CGFloat(17.0))
        
        vc.cornerColor = UIColor.blue
        vc.torchButtonImage = ScanViewController.cameraImage()

        vc.torchButtonSize = CGSize(width: 44, height: 44)
        
        self.present(vc, animated: true)
    }
    
    
    @IBAction func scanWithTimeoutPress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.allowSkip = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            vc.cancel(callDelegate: true)
        }
        self.present(vc, animated: true)
    }
    
    @IBAction func scanAndShowImagePress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.includeCardImage = true

        self.present(vc, animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func customVideoPress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        
        self.currentTestImages = self.testImages.compactMap { $0.cgImage }
        vc.testingImageDataSource = self
        vc.showDebugImageView = true
        self.present(vc, animated: true)
    }
    
    @IBAction func scanWithStatsPress() {
        ScanViewController.configure(apiKey: "0xdeadbeef")
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.scanEventsDelegate = self
        
        self.present(vc, animated: true)
    }
}

