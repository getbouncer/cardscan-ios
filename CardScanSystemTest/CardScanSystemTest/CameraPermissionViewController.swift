//
//  CameraPermissionViewController.swift
//  CardScanSystemTest
//
//  Created by Jaime Park on 10/27/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import UIKit
import os.log
import AVKit

class CameraPermissionViewController: UIViewController {
    @IBOutlet weak var cameraPermissionStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCameraPermissionStatusLabelText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.requestCameraAuthorization()
    }
    
    @IBAction func closeButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func authorizationStatusToString(for type: AVMediaType) -> String {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        default: return "Unknown"
        }
    }
    
    func setCameraPermissionStatusLabelText() {
        let statusString = authorizationStatusToString(for: .video)
        DispatchQueue.main.async {
            self.cameraPermissionStatusLabel.text = statusString
        }
    }
    
    func requestCameraAuthorization() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            self.setCameraPermissionStatusLabelText()
            return
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                self.setCameraPermissionStatusLabelText()
                return
            })
        }
    }
}
