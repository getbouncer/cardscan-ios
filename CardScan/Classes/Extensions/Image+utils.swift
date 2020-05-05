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
        let screen = UIScreen.main.bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height

        let imageCenterX = CGFloat(self.width) / 2.0
        let imageCenterY = CGFloat(self.height) / 2.0
          
        let imageAspectRatio = CGFloat(self.height) / CGFloat(self.width)
        let previewViewAspectRatio = previewViewFrame.height / previewViewFrame.width
        let screenAspectRatio = screenHeight / screenWidth
        let cropRatio = CGFloat(16.0) / CGFloat(9.0)
          
        // Get ratio to convert points to pixels
        let pointsToPixel: CGFloat = {
            // image and screen height dont match up, widths match up, get ratio with widths
            if imageAspectRatio > screenAspectRatio {
                return CGFloat(self.width) / screenWidth
            }
            // image and screenw width dont match up, heights match up, get ratio with heights
            return CGFloat(self.height) / screenHeight
        }()
         
        // Get ration to scale previewView up to image size
        let scale: CGFloat = {
            // previewView is the same size as screen so no need for scale
            if screenAspectRatio == previewViewAspectRatio {
                return 1.0
            }
            // image height is larger than its width => find ratio to scale up preview view width to match image width
            if imageAspectRatio > previewViewAspectRatio {
                return CGFloat(self.width) / (previewViewFrame.width * pointsToPixel)
            }
            // image width is larger than its height => find ratio to scale up preview view height to match image height
            return CGFloat(self.height) / (previewViewFrame.height * pointsToPixel)
        }()
        
        let fullScreenImage: CGImage? = {
            // if image is already 16:9, no need to crop to match crop ratio
            if cropRatio == imageAspectRatio {
                return self
            } else {
                // imageAspectRatio not being 16:9 implies image being in landscape
                // get width to first not cut out any card information
                let cropWidth = previewViewFrame.width * pointsToPixel * scale
                // then get height to match 16:9 ratio
                let cropHeight = cropWidth * (16.0 / 9.0)
                return self.cropping(to: CGRect(x: imageCenterX - cropWidth / 2.0, y: imageCenterY - cropHeight / 2.0, width: cropWidth, height: cropHeight))
            }
        }()
        
        let roiRect: CGRect? = {
            let roiWidth = regionOfInterestLabelFrame.width * pointsToPixel * scale
            let roiHeight = regionOfInterestLabelFrame.height * pointsToPixel * scale
            
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
