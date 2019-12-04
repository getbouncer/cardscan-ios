//
//  TestingImageExtension.swift
//  CardScan
//
//  Created by Jaime Park on 12/3/19.
//

import Foundation

extension ScanBaseViewController {    
    func testingImagesSizeCheck() -> [CGImage?]{
        guard let image = self.testingImageDataSource?.nextImage() else {
            print("could not get testing image")
            return [nil, nil]
        }
        
        if let imageIsFullScreen = self.testingImageDataSource?.imageIsFullScreen, imageIsFullScreen == true {
            let squareImage = self.toRegionOfInterest(image: image)
                return [squareImage, image]
        }
        
        return [image, nil]
    }
}
