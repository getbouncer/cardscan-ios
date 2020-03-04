//
//  CardScan.swift
//  CardScan
//
//  Created by Jaime Park on 1/29/20.
//

import Foundation

public class CardScan {
    // If you change the bundle name make sure to set these before
    // initializing the library
    public static var bundleName = "CardScan"
    public static var extensionName = "bundle"
    public static var cardScanBundle: Bundle?
    public static var scanViewControllerIsAppearing = false
    
    // Public for testing
    public static func bundle() -> Bundle? {
        if cardScanBundle != nil {
            return cardScanBundle
        }
        
        guard let bundleUrl = Bundle(for: ScanViewController.self).url(forResource: bundleName, withExtension: extensionName) else {
            print("bundleURL could not be found")
            return nil
        }
            
        guard let bundle = Bundle(url: bundleUrl) else {
            print("bundle with bundleURL could not be found")
            return nil
        }
        
        return bundle
    }
    
    static func compiledModel(forResource: String, withExtension: String) -> URL? {
        guard let bundle = bundle() else {
            return nil
        }
        
        guard let modelcUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
            print("Could not find bundle named \"\(forResource).\(withExtension)\"")
            return nil
        }
        
        return modelcUrl
    }
}
