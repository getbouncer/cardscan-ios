//
//  ViewController.swift
//  CardScanSystemTest
//
//  Created by Sam King on 7/3/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import UIKit
import CardScan
//import CardVerify
import AVKit

class ViewController: UIViewController, TestingImageDataSource {
    let testImages = [0,1,2,3,4,5,6,7,8,9].map { UIImage(imageLiteralResourceName: "bofa_frame\($0)") }
    var currentTestImages: [CGImage]?
    var currentApiTime = Api.lastScanStatsSuccess

    func nextSquareAndFullImage() -> (CGImage, CGImage)? {
        guard let fullCardImage = self.currentTestImages?.first else {
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
        
        guard let testImageCount = self.currentTestImages?.count else { return nil }
        
        if testImageCount == 0 {
            self.currentTestImages = self.testImages.compactMap { $0.cgImage }
        }
        
        return (squareCardImage, fullCardImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func acceptCameraPermissionsPress(_ sender: Any) {
        let cameraPermissionViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraPermissionViewController")
        self.present(cameraPermissionViewController, animated: true, completion: nil)
     }
    
    @IBAction func verifyMatchPress() {
        self.startVerifyViewController(bin: "463551", last4: "9347")
    }
    
    @IBAction func verifyCustomStringsPress() {
       /*
        guard let vc = Bouncer.createVerifyViewController(last4: "4242", expiryMonth: "11", expiryYear: "23", network: .VISA, withDelegate: self) else {
            print("This device is incompatible with CardVerify")
            return
        }
        
        vc.stringDataSource = self
        vc.verifyCardFont = UIFont(name: "Verdana", size: CGFloat(17.0))
        vc.explanationFont = UIFont(name: "Verdana", size: CGFloat(14.0))
        vc.paymentCardFont = UIFont(name: "Verdana", size: CGFloat(15.0))
        vc.last4ExpiryFont = UIFont(name: "Chalkduster", size: CGFloat(15.0))
        vc.scanCardButtonFont = UIFont(name: "Chalkduster", size: CGFloat(15.0))
        vc.cancelButtonImage = ScanViewController.cameraImage()
        vc.torchButtonImage = ScanViewController.cameraImage()
        vc.scanCardButtonBackgroundColor = UIColor.blue
        
        self.present(vc, animated: true)
         */
    }
    
    @IBAction func failVerifyNoMatchPress() {
        self.startVerifyViewController(bin: "463551", last4: "4242", apiError: "bin_mismatch")
    }
    
    @IBAction func failVerifyPress() {
        self.startVerifyViewController(bin: "463551", last4: "9347", apiError: "bin_mismatch")
    }
    
    @IBAction func runPress() {
        self.startScanViewController()
    }
    
    @IBAction func simpleStartPress() {
        let config = ScanConfiguration()
        config.runOnOldDevices = true
        guard let vc = ScanViewController.createViewController(withDelegate: self, configuration: config) else {
            print("This device is incompatible with CardScan")
            return
        }
        vc.allowSkip = true
        self.present(vc, animated: true)
    }
    
    @IBAction func deleteModelsPress() {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        let findFour = documentDirectory.appendingPathComponent("FindFour.mlmodelc")
        let _ = try? FileManager.default.removeItem(at: findFour)
        let fourRecognize = documentDirectory.appendingPathComponent("FourRecognize.mlmodelc")
        let _ = try? FileManager.default.removeItem(at: fourRecognize)
    }

    @IBAction func customStringsPress() {
        let config = ScanConfiguration()
        config.runOnOldDevices = true
        guard let vc = ScanViewController.createViewController(withDelegate: self, configuration: config) else {
            print("This device is incompatible with CardScan")
            return
        }
        
        vc.stringDataSource = self
        vc.allowSkip = true
        
        vc.backButtonColor = UIColor.red
        vc.hideBackButtonImage = true
        vc.backButtonImageToTextDelta = 8.0
        
        vc.backButtonFont = UIFont(name: "Verdana", size: CGFloat(17.0))
        vc.scanCardFont = UIFont(name: "Chalkduster", size: CGFloat(24.0))
        vc.positionCardFont = UIFont(name: "Chalkduster", size: CGFloat(17.0))
        vc.skipButtonFont = UIFont(name: "Chalkduster", size: CGFloat(17.0))
        
        self.present(vc, animated: true)
    }
    
    @IBAction func openImagePickerPress(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .camera
        self.present(picker, animated: true)
    }
    
    @IBAction func openCardScanPress(_ sender: Any) {
        let config = ScanConfiguration()
        config.runOnOldDevices = true
        guard let vc = ScanViewController.createViewController(withDelegate: self, configuration: config) else {
            print("This device is incompatible with CardScan")
            return
        }
        self.present(vc, animated: true)
    }
    
    @IBAction func openTorchCheckCardScanPress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TorchCheckViewController") as! TorchCheckViewController
        self.present(vc, animated: true)
    }
    
    func startVerifyViewController(bin: String, last4: String, apiError: String? = nil, useNewViewController: Bool = false) {
        /*
        if #available(iOS 11.2, *), useNewViewController {
            let vc = VerifyScanCardViewController.createVerifyScanViewController()
            vc.bin = bin
            vc.lastFour = last4
            vc.verifyScanDelegate = self
            vc.testingImageDataSource = self
            vc.showDebugImageView = true
            self.currentTestImages = self.testImages.compactMap { $0.cgImage }
            self.present(vc, animated: true)
        } else {
            guard let vc = Bouncer.createVerifyViewController(last4: last4, expiryMonth: "11", expiryYear: "23", network: .VISA, withDelegate: self) else {
                return
            }
            vc.testingImageDataSource = self
            vc.showDebugImageView = true
            self.currentTestImages = self.testImages.compactMap { $0.cgImage }

            if let apiError = apiError {
                vc.debugForceApiError = apiError
            }
            self.present(vc, animated: true)
        }*/
    }
    
    
    func startScanViewController() {
        let config = ScanConfiguration()
        config.runOnOldDevices = true
        
        guard let vc = ScanViewController.createViewController(withDelegate: self, configuration: config) else {
            print("This device is incompatible with CardScan")
            return
        }
        
        self.currentTestImages = self.testImages.compactMap { $0.cgImage }
        
        vc.testingImageDataSource = self
        vc.showDebugImageView = true
        
        self.present(vc, animated: true)
    }
}

/*
@available (iOS 11.2, *)
extension ViewController: CardVerifyResults {
    func userDidScanCard(viewController: VerifyScanCardViewController, number: String?, name: String?, expiryYear: String?, expiryMonth: String?, isCardValid: Bool, cardValidationFailureReason: String?) {
        self.dismiss(animated: true)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultViewController
        vc.cardNumber = number
        vc.verifiedMatch = isCardValid
        vc.verifiedCard = cardValidationFailureReason == nil
        self.present(vc, animated: true)
    }
    
    func userMissingCard(viewController: VerifyScanCardViewController) {
        self.dismiss(animated: true)
    }
    
    func userCanceledScan(viewController: VerifyScanCardViewController) {
        self.dismiss(animated: true)
    }
}
*/

extension ViewController: ScanDelegate {
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultViewController
        vc.cardNumber = creditCard.number
        vc.currentApiTime = self.currentApiTime
        
        self.dismiss(animated: true)
        self.present(vc, animated: true)
    }
}

extension ViewController: ScanStringsDataSource {
    func scanCard() -> String { return "New Scan Card" }
    func positionCard() -> String { return "New Position Card" }
    func backButton() -> String { return "New Back" }
    func skipButton() -> String { return "New Skip" }
}

/*
extension ViewController: VerifyStringsDataSource {
    //MARK: Custom strings protocol
    func verifyCard() -> String { return "New Verify Card" }
    func explanation() -> String { return "Do something with your card" }
    func paymentMethod() -> String { return "Debit/Credit Card" }
    func scanCardButton() -> String { return "New Scan Card" }
    func denyPermissionTitle() -> String { return "Deny title" }
    func denyPermissionMessage() -> String { return "You denied camera permissions" }
    func denyPermissionButton() -> String { return "GO" }
}

extension ViewController: VerifyDelegate {
    // MARK: VerifyDelegate protocol implementation
     func userDidScanSameCard(_ viewController: VerifyCardViewController, card: PaymentCard) {
         self.dismiss(animated: true)
         
         guard let encryptedPayload = card.encryptedPayload else {
             print("Missing encryptedPayload")
             return
         }
         
         var parameters: [String: Any] = [:]
         parameters["payload"] = encryptedPayload
         parameters["test_error"] = viewController.debugForceApiError
         
         MyAppsApi.fraudCheck(parameters: parameters) { response, error in
             // Api Request Error, No Result VC
             guard let response = response, error == nil else {
                 print(error?.message ?? "Api Error")
                 return
             }
             
             let storyboard = UIStoryboard(name: "Main", bundle: nil)
             let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultViewController
             vc.cardNumber = card.number
             
             // Api Request Response In, Failure Reasons In
             if let failureReasonArr = response["failure_reasons"] as? NSArray, failureReasonArr.count > 0 {
                 vc.verifiedMatch = !card.isNewCard
                 vc.verifiedCard = false
             } else { // Api Request Response In, No Failure Reasons In
                 vc.verifiedMatch = true
                 vc.verifiedCard = true
             }
             
             self.present(vc, animated: true)
         }
     }
     
     func userDidScanDifferentCard(_ viewController: VerifyCardViewController, card: PaymentCard) {
         self.dismiss(animated: true)
                
         guard let encryptedPayload = card.encryptedPayload else {
             print("Missing encryptedPayload")
             return
         }
        
         var parameters: [String: Any] = [:]
         parameters["payload"] = encryptedPayload
         parameters["test_error"] = viewController.debugForceApiError
        
         MyAppsApi.fraudCheck(parameters: parameters) { response, error in
             // Api Request Error, No Result VC
             guard let response = response, error == nil else {
                 print(error?.message ?? "Api Error")
                 return
             }
            
             let storyboard = UIStoryboard(name: "Main", bundle: nil)
             let vc = storyboard.instantiateViewController(withIdentifier: "results") as! ResultViewController
             vc.cardNumber = card.number
            
             // Api Request Response In, Failure Reasons In
             if let failureReasonArr = response["failure_reasons"] as? NSArray, failureReasonArr.count > 0 {
                 vc.verifiedMatch = !card.isNewCard
                 vc.verifiedCard = false
             } else { // Api Request Response In, No Failure Reasons In
                 vc.verifiedMatch = false
                 vc.verifiedCard = true
             }
            
             self.present(vc, animated: true)
         }
         
     }
         
     func userDidCancelVerify(_ viewController: VerifyCardViewController) {
         self.dismiss(animated: true)
     }
}
*/
extension ViewController: UIImagePickerControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Did cancel")
        picker.dismiss(animated: false, completion: nil)
    }
    
    #if swift(<4.2)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("didFinishPickingMediaWithInfo")
        picker.dismiss(animated: false) {
            NotificationCenter.default.removeObserver(picker.cameraDevice)
            NotificationCenter.default.removeObserver(picker)
        }
    }
    #elseif swift(>=4.2)
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("didFinishPickingMediaWithInfo")
        picker.dismiss(animated: false) {
            NotificationCenter.default.removeObserver(picker.cameraDevice)
            NotificationCenter.default.removeObserver(picker)
        }
    }
    #endif
   
    
}

extension ViewController: UINavigationControllerDelegate {
    // This delegate is required but at this point no methods are needed
}

