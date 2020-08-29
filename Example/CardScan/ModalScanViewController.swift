//
//  ModalScanViewController.swift
//  CardScan_Example
//
//  Created by Jaime Park on 6/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import CardScanPrivate

class ModalScanViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cancelButton.action = #selector(cancelButtonPress(sender:))
        self.cancelButton.target = self
    }

    @objc func cancelButtonPress(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toScanViewPress(_ sender: Any) {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            return
        }
        
        vc.stringDataSource = self
        vc.hideBackButtonImage = true
        vc.navigationBarIsHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func toScanViewModalPress(_ sender: Any) {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
            return
        }
        
        vc.navigationBarIsHidden = true
        vc.modalPresentationStyle = .formSheet
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ModalScanViewController: ScanDelegate {
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.navigationController?.popViewController(animated: true)
        print("User Did Cancel")
    }

    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        self.navigationController?.popViewController(animated: true)
        print("User Did Scan Card \(creditCard.number)")
    }

    func userDidSkip(_ scanViewController: ScanViewController) {
        self.navigationController?.popViewController(animated: true)
        print("User Did Skip")
    }
}

extension ModalScanViewController: ScanStringsDataSource {
    func scanCard() -> String { return "Scan Card Title" }
    func positionCard() -> String { return "Card Positioning Description" }
    func backButton() -> String { return "" }
    func skipButton() -> String { return "Skip Button Title" }
}
