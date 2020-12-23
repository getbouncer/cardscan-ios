//
//  LaunchViewController.swift
//  TestOcr
//
//  Created by Sam King on 10/30/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import UIKit

import CardScan

class LaunchViewController: UIViewController {
    
    @IBAction func runTestOcrDdPress() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "viewController") as! ViewController
        vc.ocr = SSDCreditCardOcr(dispatchQueueLabel: "TestOcr DD")
        present(vc, animated: true)
    }
    
    @IBAction func runTestOcrApplePress() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "viewController") as! ViewController
        vc.ocr = AppleCreditCardOcr(dispatchQueueLabel: "TestOcr Apple")
        present(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
