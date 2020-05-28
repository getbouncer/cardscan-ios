import VideoToolbox
import UIKit

extension UIImage {
    static func grayImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        UIColor.gray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImage {
    func drawBoundingBoxesOnImage(boxes: [(UIColor, CGRect)]) -> UIImage? {
        let image = UIImage(cgImage: self)
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint(x: 0,y :0))
        
        UIGraphicsGetCurrentContext()?.setLineWidth(3.0)
        
        for (color, box) in boxes {
            color.setStroke()
            UIRectFrame(box)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func toFullScreenAndRoi(previewViewFrame: CGRect, regionOfInterestLabelFrame: CGRect) -> (CGImage, CGRect)? {
        let imageCenterX = CGFloat(self.width) / 2.0
        let imageCenterY = CGFloat(self.height) / 2.0
            
        let imageAspectRatio = CGFloat(self.height) / CGFloat(self.width)
        let previewViewAspectRatio = previewViewFrame.height / previewViewFrame.width
        let cropRatio = CGFloat(16.0) / CGFloat(9.0)
            
        // Get ratio to convert points to pixels
        let pointsToPixel: CGFloat = imageAspectRatio > previewViewAspectRatio ? CGFloat(self.width) / previewViewFrame.width : CGFloat(self.height) / previewViewFrame.height
          
        let fullScreenImage: CGImage? = {
            // if image is already 16:9, no need to crop to match crop ratio
            if cropRatio == imageAspectRatio {
                return self
            } else {
                // imageAspectRatio not being 16:9 implies image being in landscape
                // get width to first not cut out any card information
                let cropWidth = previewViewFrame.width * pointsToPixel
                // then get height to match 16:9 ratio
                let cropHeight = cropWidth * (16.0 / 9.0)
                return self.cropping(to: CGRect(x: imageCenterX - cropWidth / 2.0, y: imageCenterY - cropHeight / 2.0, width: cropWidth, height: cropHeight))
            }
        }()
          
        let roiRect: CGRect? = {
            let roiWidth = regionOfInterestLabelFrame.width * pointsToPixel
            let roiHeight = regionOfInterestLabelFrame.height * pointsToPixel
              
            guard let fullScreenImage = fullScreenImage else { return nil }
            let fullScreenCenterX = CGFloat(fullScreenImage.width) / 2.0
            let fullScreenCenterY = CGFloat(fullScreenImage.height) / 2.0
              
            return CGRect(x: fullScreenCenterX - roiWidth / 2.0, y: fullScreenCenterY - roiHeight / 2.0, width: roiWidth, height: roiHeight)
        }()
          
        guard let regionOfInterestRect = roiRect, let fullScreenCgImage = fullScreenImage else { return nil }
        return (fullScreenCgImage, regionOfInterestRect)
    }
}

extension CVPixelBuffer {
    func cgImage() -> CGImage? {
        var cgImage: CGImage?
        if #available(iOS 9.0, *) {
            #if swift(>=4.2)
                VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
            #else
                VTCreateCGImageFromCVPixelBuffer(self, nil, &cgImage)
            #endif
        } else {
            return nil
        }
        
        return cgImage
    }
}
