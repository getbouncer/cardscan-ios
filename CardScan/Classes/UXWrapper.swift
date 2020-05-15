//
//  UXWrapper.swift
//  CardScan
//
//  Created by xaen on 5/15/20.
//

import Foundation

public class UXWrapper{
    public init(){}

    static func configure(){
        if #available(iOS 11.2, *){
            let ux = UXDetect()
            ux.warmUp()
        }
    }

    @available(iOS 11.2, *)
    public func perform(croppedCardImage: CGImage) -> String?{
        let ux = UXDetect()
        var _ = ux.predict(image: UIImage(cgImage: croppedCardImage))
        return nil
    }

}
