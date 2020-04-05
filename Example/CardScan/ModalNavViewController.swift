//
//  ModalNavViewController.swift
//  CardScan_Example
//
//  Created by Jaime Park on 3/31/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class ModalNavViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var shouldAutorotate: Bool {
        return visibleViewController!.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return visibleViewController!.supportedInterfaceOrientations
    }
}
