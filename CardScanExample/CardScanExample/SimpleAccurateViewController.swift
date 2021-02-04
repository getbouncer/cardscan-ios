//
//  SimpleAccurateViewController.swift
//  CardScanExample
//
//  Created by Jaime Park on 2/4/21.
//
import CardScan
import UIKit

class SimpleAccurateViewController: UIViewController {
    var startTime: Date = Date()
    let scanErrorCorrectionDuration = 7.0
    let expiryLabelText = "Expiration extraction:"
    let errorCorrectionLabelText = "Approx scan time:"
    
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var errorCorrectionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        expiryLabel.isHidden = true
        errorCorrectionLabel.isHidden = true
    }
        
    @IBAction func openSimpleAccuratePress(_ sender: Any) {
        if #available(iOS 11.2, *) {
            let vc = SimpleScanViewController.createViewController()
            vc.scanPerformancePriority = .accurate
            vc.maxErrorCorrectionDuration = scanErrorCorrectionDuration
            vc.includeCardImage = true
            vc.delegate = self
            startTime = Date()
            self.present(vc, animated: true)
        } else {
            // Fallback on earlier versions
        }
    }
}

extension SimpleAccurateViewController: SimpleScanDelegate {
    func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard) {
        dismiss(animated: true, completion: nil)
        let totalViewDuration = -startTime.timeIntervalSinceNow
        expiryLabel.isHidden = false
        errorCorrectionLabel.isHidden = false

        expiryLabel.text = "\(expiryLabelText) \(creditCard.expiryForDisplay() ?? "N/A")"
        errorCorrectionLabel.text = "\(errorCorrectionLabelText) \(totalViewDuration)"
    }
}
