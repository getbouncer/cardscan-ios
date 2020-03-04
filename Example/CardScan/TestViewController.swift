//
//  TestViewController.swift
//  CardScan_Example
//
//  Created by Jaime Park on 2/21/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import CardScan

class TestViewController: UIViewController, ScanDelegate {
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func toScanViewPress(_ sender: Any) {
        guard let vc = ScanViewController.createViewController() else {
            return
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
