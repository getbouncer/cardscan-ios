//
//  LandscapeNavViewController.swift
//  CardScan_Example
//
//  Created by Jaime Park on 4/25/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class LandscapeNavViewController: UINavigationController {

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
