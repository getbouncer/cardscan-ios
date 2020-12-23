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
        
        // make sure that we have the full_videos.json and apikey.json files
        guard let url = Bundle.main.url(forResource: "full_videos", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url),
              let _ = try? JSONSerialization.jsonObject(with: jsonData) as? [[String : String]] else {
            print("could not find `full_videos.json` in the bundle, make sure that you")
            print("download a copy of it and put it in the `json` directory of the")
            print("TestOcr project. You can download the file here:")
            print("")
            print("https://drive.google.com/drive/folders/1rRmyixF62GeYIkn1tW1F81Jo3HH2c89r")
            preconditionFailure()
        }
        
        guard let url2 = Bundle.main.url(forResource: "apikey", withExtension: "json"),
              let jsonData2 = try? Data(contentsOf: url2),
              let apiData = try? JSONSerialization.jsonObject(with: jsonData2) as? [String : String] else {
            print("could not find `apikey.json` in the bundle, make sure that you")
            print("download a copy of it and put it in the `json` directory of the")
            print("TestOcr project. You can download the file here:")
            print("")
            print("https://drive.google.com/drive/folders/1rRmyixF62GeYIkn1tW1F81Jo3HH2c89r")
            preconditionFailure()
        }
        
        ViewController.apiKey = apiData["apikey"]
    }
    
}
