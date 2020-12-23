//
//  ResultViewController.swift
//  CardScanSystemTest
//
//  Created by Sam King on 7/5/19.
//  Copyright © 2019 Sam King. All rights reserved.
//

import UIKit
import CardScan

class ResultViewController: UIViewController {

    var cardNumber: String?
    var currentApiTime: Date?
    var verifiedCard: Bool?
    var verifiedMatch: Bool?
    
    @IBOutlet weak var verifyLabel: UILabel!
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var apiResultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let cardNumber = self.cardNumber {
            self.cardNumberLabel.text = cardNumber
        }
        
        if let verifiedCard = self.verifiedCard, let verifiedMatch = self.verifiedMatch {
            self.verifyLabel.isHidden = false
            self.verifyLabel.text = "verify \(verifiedCard) match \(verifiedMatch)"
        }
        
        self.apiResultLabel.text = "API key = \(Api.apiKey)"
        self.apiResultLabel.isHidden = false
        
        DispatchQueue.global(qos: .background).async {
            var hasResult = false
            while !hasResult {
                Thread.sleep(forTimeInterval: 0.1)
                if Api.lastScanStatsSuccess != self.currentApiTime {
                    hasResult = true
                    DispatchQueue.main.async {
                        self.apiResultLabel.isHidden = false
                    }
                }
            }
        }
    }
}
