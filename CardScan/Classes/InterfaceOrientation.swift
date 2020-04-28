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
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portrait_upside_down"
        case .landscapeRight: return "landscape_right"
        case .landscapeLeft: return "landscape_left"
        case .unknown: return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}
