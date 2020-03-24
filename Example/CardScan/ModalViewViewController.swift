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

class ModalViewViewController: UIViewController, ScanDelegate {
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.navigationController?.popToRootViewController(animated: true)
        print("User Did Cancel")
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        self.navigationController?.popToRootViewController(animated: true)
        print("User Did Scan Card \(creditCard.number)")
    }
    
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.navigationController?.popToRootViewController(animated: true)
        print("User Did Skip")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func toScanViewPress(_ sender: Any) {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            return
        }
        
        vc.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}

