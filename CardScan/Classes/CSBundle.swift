//
//  CardScan.swift
//  CardScan
//
//  Created by Jaime Park on 1/29/20.
//

import Foundation

public class CSBundle {
    // If you change the bundle name make sure to set these before
    // initializing the library
    public static var name = "CardScan"
    public static var extensionName = "bundle"
    public static var bundle: Bundle?
    
    // Public for testing
    public static func getBundle() -> Bundle? {
        if bundle != nil {
            return bundle
        }
        
        guard let bundleUrl = Bundle(for: ScanViewController.self).url(forResource: name, withExtension: extensionName) else {
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
        guard let bundle = getBundle() else {
            return nil
        }
        
        guard let modelcUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
            print("Could not find bundle named \"\(forResource).\(withExtension)\"")
            return nil
        }
        
        return modelcUrl
    }
}
