import AVKit
import VideoToolbox

class VideoFeed {
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDevice: AVCaptureDevice?
    
    var torch: Torch?
    
    func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
            })
            
        default:
            // The user has previously denied access.
            self.setupResult = .notAuthorized
        }
    }
    
    func setup(captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, completion: @escaping ((_ success: Bool) -> Void)) {
        sessionQueue.async { self.configureSession(captureDelegate: captureDelegate, completion: completion) }
    }
    
    
    func configureSession(captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, completion: @escaping ((_ success: Bool) -> Void)) {
        if setupResult != .success {
            DispatchQueue.main.async { completion(false) }
            return
        }
        
        session.beginConfiguration()
        
        if session.canSetSessionPreset(.iFrame960x540) {
            session.sessionPreset = .iFrame960x540
        }
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if #available(iOS 10.2, *) {
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                    defaultVideoDevice = dualCameraDevice
                } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    // If the back dual camera is not available, default to the back wide angle camera.
                    defaultVideoDevice = backCameraDevice
                } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    /*
                     In some cases where users break their phones, the back wide angle camera is not available.
                     In this case, we should default to the front wide angle camera.
                     */
                    defaultVideoDevice = frontCameraDevice
                }
            } else {
                // Fallback on earlier versions
            }
            
            guard let myVideoDevice = defaultVideoDevice else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            self.videoDevice = myVideoDevice
            self.torch = Torch(device: myVideoDevice)
            let videoDeviceInput = try AVCaptureDeviceInput(device: myVideoDevice)
            
            self.setupVideoDeviceDefaults()
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            let videoDeviceOutput = AVCaptureVideoDataOutput()
            videoDeviceOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            
            videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
            let captureSessionQueue = DispatchQueue(label: "camera output queue")
            videoDeviceOutput.setSampleBufferDelegate(captureDelegate, queue: captureSessionQueue)
            guard session.canAddOutput(videoDeviceOutput) else {
                print("Could not add video device output to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            session.addOutput(videoDeviceOutput)
            
            let connection = videoDeviceOutput.connection(with: .video)
            if connection?.isVideoOrientationSupported ?? false {
                connection?.videoOrientation = .portrait
            }
            
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            DispatchQueue.main.async { completion(false) }
            return
        }
        
        session.commitConfiguration()
        DispatchQueue.main.async { completion(true) }
    }
    
    func setupVideoDeviceDefaults() {
        guard let videoDevice = self.videoDevice else {
            return
        }
        
        guard let _ = try? videoDevice.lockForConfiguration() else {
            print("can't lock video device")
            return
        }
        
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            videoDevice.focusMode = .continuousAutoFocus
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = true
            }
        }
        
        if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
            videoDevice.exposureMode = .continuousAutoExposure
        }
        
        if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        
        if videoDevice.isLowLightBoostSupported {
            videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
        videoDevice.unlockForConfiguration()
    }
    
    func toggleTorch() {
        self.torch?.toggle()
    }
    
    func willAppear() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case _:
                print("could not start session")
            }
        }
    }
    
    func willDisappear() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}
