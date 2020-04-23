//
//  InterfaceOrientation.swift
//  CardScan
//
//  Created by Jaime Park on 4/23/20.
//
import UIKit

extension UIWindow {
    static var interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation ?? .unknown
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
    
    static var interfaceOrientationToString: String {
        switch (self.interfaceOrientation) {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "PortraitUpsideDown"
        case .landscapeRight: return "LandscapeRight"
        case .landscapeLeft: return "LandscapeLeft"
        case .unknown: return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}
