//
//  CGrect+utils.swift
//  CardScan
//
//  Created by Jaime Park on 6/11/21.
//

import CoreGraphics

@available(*, deprecated, message: "Replaced by stripe card scan. See https://github.com/stripe/stripe-ios/tree/master/StripeCardScan")
extension CGRect {
    func centerY() -> CGFloat {
        return (minY / 2 + maxY / 2)
    }
    
    func centerX() -> CGFloat {
        return (minX / 2 + maxX / 2)
    }
}
