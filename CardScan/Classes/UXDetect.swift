//
//  UXDetect.swift
//  CardScan
//
//  Created by xaen on 5/14/20.
//
import Foundation
import os.log

@available(iOS 11.2, *)

struct UXDetect {
    static var uxModel: uxmodel? = nil
    static let uxResource = "uxmodel"
    static let uxExtension = "mlmodelc"
    
    let uxImageHeight = 224
    let uxImageWidth = 224
    
    func warmUp() {
        UXDetect.initializeModels()
        UIGraphicsBeginImageContext(CGSize(width: uxImageWidth,
                                           height: uxImageHeight))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: uxImageWidth,
                                      height: uxImageHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let uxModel = UXDetect.uxModel else{
            print("Model not initialized")
            return
        }
        if let pixelBuffer = newImage?.pixelBuffer(width: uxImageWidth,
                                                   height: uxImageHeight){
            let input = uxmodelInput(input1: pixelBuffer)
            let _ = try? uxModel.prediction(input: input)
        }
    }
    
    static func initializeModels() {
        
        if UXDetect.uxModel == nil {
            guard let uxUrl  = CSBundle.compiledModel(forResource: uxResource, withExtension: uxExtension) else {
                print("Could not find URL for ux model")
                return
            }
    
            guard let uxModel = try? uxmodel(contentsOf: uxUrl) else {
                print("Could not get contents of recognize model with fourRecognize URL")
                return
            }
    
            UXDetect.uxModel = uxModel

    }
    }
    public func predict(image: UIImage) -> String? {
        
        UXDetect.initializeModels()
        guard let pixelBuffer = image.pixelBuffer(width: uxImageWidth,
                                                  height: uxImageHeight)
        else {
            os_log("Couldn't convert to pixel buffer", type: .debug)
            return nil
                                                    
        }
        
        guard let uxModel = UXDetect.uxModel else {
            os_log("Model not initialized", type: .debug)
            return nil
        }
        
        //let startTime = CFAbsoluteTimeGetCurrent()
        let input = uxmodelInput(input1: pixelBuffer)
        
        guard let prediction = try? uxModel.prediction(input: input) else {
            os_log("Couldn't predict", type: .debug)
            return nil
        }
        
        //let endTime = CFAbsoluteTimeGetCurrent() - startTime
        //os_log("%@", type: .debug, "Model Run without post-process time: \(endTime)")
        
        return "Success"

    }

    
    
    
}
