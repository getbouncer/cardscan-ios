//
//  MyScanViewController.swift
//  CardScanSystemTest
//
//  Created by Jaime Park on 12/2/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import UIKit
import CardScan

class TorchCheckViewController: ScanBaseViewController {

    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var blurView: BlurView!
    @IBOutlet weak var regionOfInterestLabel: UILabel!
    @IBOutlet weak var cornerView: CornerView!
    @IBOutlet weak var debugImageView: UIImageView!
    @IBOutlet weak var torchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupOnViewDidLoad(regionOfInterestLabel: self.regionOfInterestLabel, blurView: self.blurView, previewView: self.previewView, cornerView: self.cornerView, debugImageView: self.debugImageView, torchLevel: 1.0)
        self.startCameraPreview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cornerView.layer.borderColor = UIColor.yellow.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.hasTorchAndIsAvailable() {
            self.torchButton.isHidden = true
        }
    }

    @IBAction func backButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func torchButtonPress(_ sender: Any) {
        self.toggleTorch()
    
        if self.isTorchOn() {
            self.torchButton.layer.backgroundColor = UIColor.black.cgColor
            self.torchButton.setTitle("Turn Off", for: .normal)
        } else {
            self.torchButton.layer.backgroundColor = UIColor.green.cgColor
            self.torchButton.setTitle("Turn On", for: .normal)
        }
                    
    }
}
