//
//  AppDelegate.swift
//  CardScanSystemTest
//
//  Created by Sam King on 7/3/19.
//  Copyright © 2019 Sam King. All rights reserved.
//
import CardScan
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // check the environment variable first, if our API key is here use it and finish up
        if let apiKeyEnv = ProcessInfo.processInfo.environment["CARDSCAN_SYSTEM_TEST_API_KEY"] {
            ScanBaseViewController.configure(apiKey: apiKeyEnv)
            return true
        }
        
        let bundle = Bundle(for: AppDelegate.self)
        guard let apiKeyJsonUrl = bundle.url(forResource: "apikey", withExtension: "json") else {
            print("make sure that you create an 'apikey.json' file in the Resources dir")
            return false
        }
        
        guard let rawData = try? Data(contentsOf: apiKeyJsonUrl) else {
            print("could not read 'apikey.json' from bundle")
            return false
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: rawData), let jsonObject = jsonData as? [String: Any] else {
            print("apikey.json does not appear to be a valid json object")
            return false
        }
        
        guard let apiKey = jsonObject["apikey"] as? String else {
            print("could not find the 'apikey' item in the apikey.json object")
            return false
        }
        
        ScanBaseViewController.configure(apiKey: apiKey)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

