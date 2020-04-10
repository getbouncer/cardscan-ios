//
//  AppDelegate.swift
//  CardScan
//
//  Created by Sam King on 10/15/2018.
//  Copyright (c) 2018 Sam King. All rights reserved.
//

import UIKit
import CardScan

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let bundle = CSBundle.bundle()
        CSBundle.cardScanBundle = bundle
        CSBundle.bundleName = ""
        CSBundle.extensionName = ""
        ScanViewController.configure()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return ScanBaseViewController.supportedOrientationMaskOrDefault()
    }
}

