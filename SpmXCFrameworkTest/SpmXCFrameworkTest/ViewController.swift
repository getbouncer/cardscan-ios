//
//  ViewController.swift
//  SpmXCFrameworkTest
//
//  Created by Sam King on 12/17/20.
//
import CardScan
import CommonCrypto
import CoreML
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var allDoneLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allDoneLabel.isHidden = true
        activityIndicator.isHidden = true
    }

    @IBAction func runTestPress() {
        activityIndicator.isHidden = false
        DispatchQueue.global(qos: .background).async {
            let _ = ViewController.copyTest()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.activityIndicator.isHidden = true
                self.allDoneLabel.isHidden = false
            }
        }
    }
    
    static func printHashOfFiles(in url: URL, descriptor: String, suffix: String) -> Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) else {
            print("could not fetch contents of copy")
            return false
        }
        
        for item in contents {
            guard let isDirectory = try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
                print("could not check for directory \(descriptor)")
                return false
            }
            if !isDirectory {
                let hash = (try? Data(contentsOf: item).sha256.hex) ?? "N/A"
                print("\(suffix)/\(item.lastPathComponent) -> \(hash)")
            } else {
                if !printHashOfFiles(in: item, descriptor: descriptor, suffix: suffix + "/" + item.lastPathComponent) {
                    return false
                }
            }
        }
        
        return true
    }
    
    static func copyTest() -> Bool {
        
        guard let scanUrl = Bundle(identifier: "com.getbouncer.CardScan")?.url(forResource: "SSDOcr", withExtension: "mlmodelc") else {
            print("no main mlmodelc url")
            return false
        }
        
        print("calculating hashes for main")
        guard printHashOfFiles(in: scanUrl, descriptor: "main", suffix: "") else { return false }
        print("")
                
        print("loading main model")
        if let _ = try? MLModel(contentsOf: scanUrl) {
            print("main model loaded")
        } else {
            print("couldn't load main model")
            return false
        }
        
        return true
    }
    
}

struct Digest {
    static func sha256(bytes: UnsafeRawBufferPointer, length: UInt32) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(bytes.baseAddress, length, &hash)
        return hash
    }
}

extension Data {
    var hex: String {
        return map { String(format: "%02x", $0) }.reduce("", +)
    }
    
    public var sha256: Data {
        return digest(Digest.sha256)
    }
    
    private func digest(_ function: ((UnsafeRawBufferPointer, UInt32) -> [UInt8])) -> Data {
        var hash: [UInt8] = []
        withUnsafeBytes { hash = function($0, UInt32(count)) }
        return Data(bytes: hash, count: hash.count)
    }
    
}
