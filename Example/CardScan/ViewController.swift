//
//  ViewController.swift
//  CardScan
//
//  Created by Sam King on 10/15/2018.
//  Copyright (c) 2018 Sam King. All rights reserved.
//

import UIKit
import CardScan

class ViewController: UIViewController, ScanDelegate {
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
        
        self.dismiss(animated: true)
        self.present(vc, animated: true)
    }

    func userDidScanQrCode(_ scanViewController: ScanViewController, payload: String) {
        self.dismiss(animated: true)
        print(payload)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    @IBOutlet weak var scanCardButton: UIButton!
    
    @IBAction func scanQrCodePress() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.scanQrCode = true
        self.present(vc, animated: true)
    }
    @IBAction func scanCardFakeOnly() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            print("scan view controller not supported on this hardware")
            return
        }
        vc.allowSkip = true
        self.present(vc, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("memory warning!!!!")
    }

}

