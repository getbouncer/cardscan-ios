import Foundation
import DeviceCheck

public struct DeviceSecurity {
    static let kDeviceIdKey = "bouncer.deviceId"
    
    public static func configure() {
        
    }
    
    /**
     Creates a payload that we use for implementing the device abstraction.
     
     This function returns immediately and posts the base64 encoded string
     back to the caller on the main dispatch queue. You can pass this string
     to the Bouncer Device Service directly, which will interpret it.
     
     */
    public static func generatePayload(completion: @escaping (String) -> Void) {
        let startTime = Date()
        let deviceId = DeviceSecurity.localDeviceId()
        let device = DCDevice.current
        
        var payload = ["local_device_id": deviceId,
                       "platform": "ios",
                       "model": deviceModel(),
                       "os_version": osVersion()]
        
        #if DEBUG
            payload["is_debug_build"] = "yes"
        #endif
        
        guard device.isSupported else {
            DispatchQueue.main.async {
                completion(base64(from: payload))
            }
            return
        }
        
        let generateTime = Date()
        device.generateToken() { data, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(base64(from: payload))
                }
                return
            }
            
            let deviceCheckToken = data.base64EncodedString()
            DispatchQueue.main.async {
                print("Device check time: \(-startTime.timeIntervalSinceNow)")
                print("Generate time: \(-generateTime.timeIntervalSinceNow)")
                payload["device_check_token"] = deviceCheckToken
                completion(base64(from: payload))
            }
        }
    }
    
    static func base64(from payload: [String: String]) -> String {
        let json = try! JSONSerialization.data(withJSONObject: payload)
        return json.base64EncodedString()
    }
    
    static func localDeviceId() -> String {
        guard let deviceId = UserDefaults.standard.string(forKey: kDeviceIdKey) else {
            let deviceId = randomString()
            UserDefaults.standard.set(deviceId, forKey: kDeviceIdKey)
            UserDefaults.standard.synchronize()
            
            return deviceId
        }
        
        return deviceId
    }
    
    static func osVersion() -> String {
        let version = ProcessInfo().operatingSystemVersion
        return String(format: "%d.%d.%d", version.majorVersion,
            version.minorVersion, version.patchVersion)
    }
    
    static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceModel = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                // not really sure what to do here, probably won't happen
                return deviceModel
            }
            
            if charDigit == 0 {
                break
            }
            
            deviceModel += String(UnicodeScalar(UInt8(charDigit)))
        }
        
        return deviceModel
    }
    
    static func randomString() -> String {
        var bytes = [UInt8](repeating: 0, count: 24)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        // fall back to the system random number generator if we
        // can't use the cryptographic one
        if status != errSecSuccess {
            var rand = SystemRandomNumberGenerator()
            for idx in 0..<bytes.count {
                bytes[idx] = rand.next()
            }
        }
        
        return Data(bytes).base64EncodedString()
    }
}
