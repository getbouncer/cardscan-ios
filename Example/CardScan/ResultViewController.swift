//
//  ResultViewController.swift
//  CardScan_Example
//
//  Created by Sam King on 11/16/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CardScan

class ResultViewController: UIViewController {

    @IBOutlet weak var backgroundImage: UIImageView!

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var expirationLabel: UILabel!
    @IBOutlet weak var bin0: UIImageView!
    @IBOutlet weak var last0: UIImageView!
    
    var scanStats: ScanStats?
    var number: String?
    var expiration: String?
    var cardImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let scanStats = self.scanStats else {
            return
        }
        
        if let image = self.cardImage {
            self.backgroundImage.image = image
        } else {
            self.backgroundImage.image = scanStats.backgroundImage()
        }
        self.bin0.image = scanStats.binImage()
        self.last0.image = scanStats.last4Image()
      
        self.numberLabel.text = format(number: self.number ?? "")
        self.expirationLabel.text = expiration ?? ""
    }
    
    func format(number: String) -> String {
        if number.count == 16 {
            return format16(number: number)
        } else if number.count == 15 {
            return format15(number: number)
        } else {
            return number
        }
    }
    
    func format15(number: String) -> String {
        var displayNumber = ""
        for (idx, char) in number.enumerated() {
            if idx == 4 || idx == 10 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
    
    func format16(number: String) -> String {
        var displayNumber = ""
        for (idx, char) in number.enumerated() {
            if (idx % 4) == 0 && idx != 0 {
                displayNumber += " "
            }
            displayNumber += String(char)
        }
        return displayNumber
    }
    
    @IBAction func donePress(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
