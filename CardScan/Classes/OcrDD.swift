//
//  OcrDD.swift
//  CardScan
//
//  Created by xaen on 4/14/20.
//

import Foundation


public class OcrDD{
    public var scanStats = ScanStats()
    public init(){}

    static func configure(){
        if #available(iOS 11.2, *){
            let ssdOcr = SSDOcrDetect()
            ssdOcr.warmUp()
        }
    }

    @available(iOS 11.2, *)
    public func perform(croppedCardImage: CGImage) -> String?{
        var ssdOcr = SSDOcrDetect()
        let number = ssdOcr.predict(image: UIImage(cgImage: croppedCardImage))
        self.scanStats.lastFlatBoxes = ssdOcr.lastDetectedBoxes
        return number
    }

}
