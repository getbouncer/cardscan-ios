import Foundation
import AVFoundation

struct Torch {
    enum State {
        case off
        case on
    }
    let device: AVCaptureDevice?
    var state: State
    var lastStateChange: Date
    
    init(device: AVCaptureDevice) {
        self.state = .off
        self.lastStateChange = Date()
        if device.hasTorch {
            self.device = device
            if device.isTorchActive { self.state = .on }
        } else {
            self.device = nil
        }
    }
    
    mutating func toggle() {
        self.state = self.state == .on ? .off : .on

        do {
            try self.device?.lockForConfiguration()
            if self.state == .on {
                do { try self.device?.setTorchModeOn(level: 0.5) } catch { print("could not set torch mode on") }
            } else {
                self.device?.torchMode = .off
            }
            self.device?.unlockForConfiguration()
        } catch {
            print("error setting torch level")
        }
    }
    
    mutating func luma(_ value: Double) {
        let duration: Double = self.lastStateChange.timeIntervalSinceNow * -1.0
        var newState = self.state
        switch (self.state, value, duration) {
        case (.off, ..<0.4, 3.0...):
            newState = .on
        case (.on, _, 20.0...):
            newState = .off
        default:
            newState = self.state
        }

        if self.state != newState {
            self.lastStateChange = Date()
            self.state = newState
            
            do {
                try self.device?.lockForConfiguration()
                if self.state == .on {
                    do { try self.device?.setTorchModeOn(level: 0.005) } catch { print("could not set torch mode on") }
                } else {
                    self.device?.torchMode = .off
                }
                self.device?.unlockForConfiguration()
            } catch {
                print("error setting torch level")
            }
        }
    }
    
}
