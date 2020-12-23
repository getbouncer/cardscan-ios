//
//  ResultsViewController.swift
//  TestOcr
//
//  Created by Sam King on 11/19/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var results: [TestStats]?
    
    @IBOutlet weak var overallResults: UILabel!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = self.results![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "result") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "result")
        
        let recall = 100.0 * Double(result.correct) / Double(result.scans)
        let precision = 100.0 * Double(result.correct) / (Double(result.correct) + Double(result.incorrect))
        let expiryRecall = 100.0 * Double(result.expiryCorrect) / Double(result.scans)
        let expiryPrecision = 100.0 * Double(result.expiryCorrect) / (Double(result.expiryCorrect) + Double(result.expiryIncorrect))
        let averageTime = result.duration / Double(result.scans)
        
        var binAccuracy: Double?
        var binAverageTime: Double?
        if result.binsChecked() > 0 {
            binAccuracy = 100.0 * Double(result.binCheckCorrect) / Double(result.binsChecked())
            binAverageTime = result.binDuration / Double(result.binsChecked())
        }
        
        let binAccuracyString = binAccuracy.map { String(format: "%0.1f%%", $0) } ?? "N/A"
        let binAverageTimeString = binAverageTime.map { String(format: "%0.3f", $0) } ?? "N/A"
        
        let binString = "bin accuracy \(binAccuracyString), ave time \(binAverageTimeString)"
        
        cell.textLabel?.text = String(format: "Recall: %0.1f%%, Precision: %0.1f%% Expiry (%0.1f%% %0.1f%%) ",
                                      recall, precision, expiryRecall, expiryPrecision) + result.card
        cell.detailTextLabel?.text = String(format: "Average scan time: %0.3f ", averageTime) + binString
        
        return cell
    }

    @IBAction func pressRecord() {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scans = results?.reduce(0) { $0 + $1.scans } ?? 0
        let correct = results?.reduce(0) { $0 + $1.correct } ?? 0
        let incorrect = results?.reduce(0) { $0 + $1.incorrect } ?? 0
        
        let recall = 100.0 * Double(correct) / Double(scans)
        let precision = 100.0 * Double(correct) / (Double(correct) + Double(incorrect))
        
        let expiryCorrect = results?.reduce(0) { $0 + $1.expiryCorrect } ?? 0
        let expiryIncorrect = results?.reduce(0) { $0 + $1.expiryIncorrect } ?? 0
        
        let expiryRecall = 100.0 * Double(expiryCorrect) / Double(scans)
        let expiryPrecision = 100.0 * Double(expiryCorrect) / (Double(expiryCorrect) + Double(expiryIncorrect))
        
        let binCorrect = results?.reduce(0) { $0 + $1.binCheckCorrect } ?? 0
        let binTotal = results?.reduce(0) { $0 + $1.binsChecked() } ?? 0
        let binAccuracy = 100.0 * Double(binCorrect) / Double(binTotal)
        
        self.overallResults.text = String(format:"Overall recall %0.1f%%, precision %0.1f%% Expiry recall %0.1f%%, precision %0.1f%% BinCheck %0.1f%%",
                                          recall, precision, expiryRecall, expiryPrecision, binAccuracy)
    }
}
