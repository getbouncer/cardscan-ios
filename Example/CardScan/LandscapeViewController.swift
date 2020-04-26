//
//  ModalViewViewController.swift
//  CardScan_Example
//
//  Created by Jaime Park on 3/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import CardScan

class LandscapeViewController: UIViewController, ScanDelegate {
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        print("User Did Cancel")
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        print("User Did Scan Card \(creditCard.number)")
    }
    
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        print("User Did Skip")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toScanViewPress(_ sender: Any) {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            return
        }
        
        vc.modalPresentationStyle = .formSheet
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}

