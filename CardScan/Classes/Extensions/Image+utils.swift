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
    
    func toRegionOfInterest(regionOfInterestLabelFrame: CGRect) -> CGRect? {
        // get device screen size
        let screen = UIScreen.main.bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        // ROI center in Points
        let regionOfInterestCenterX = regionOfInterestLabelFrame.origin.x + regionOfInterestLabelFrame.size.width / 2.0
        
        let regionOfInterestCenterY = regionOfInterestLabelFrame.origin.y + regionOfInterestLabelFrame.size.height / 2.0
        
        // calculate center of cropping region in Pixels.
        var cx, cy: CGFloat

        // Find out whether left/right or top/bottom of the image was cropped before it was displayed to previewView.
        // The size of the cropped region is needed to map regionOfInterestCenter to the image center
        let imageAspectRatio = CGFloat(self.width) / CGFloat(self.height)
        let screenAspectRatio = screenWidth / screenHeight
        
        var pointsToPixels: CGFloat
        // convert from points to pixels and account for the cropped region
        if imageAspectRatio > screenAspectRatio {
            // left and right of the image cropped
            //      tested on: iPhone XS Max
            let croppedOffset = (CGFloat(self.width) - CGFloat(self.height) * screenAspectRatio) / 2.0
            pointsToPixels = CGFloat(self.height) / screenHeight
            
            cx = regionOfInterestCenterX * pointsToPixels + croppedOffset
            cy = regionOfInterestCenterY * pointsToPixels
        } else {
            // top and bottom of the image cropped
            //      tested on: iPad Mini 2
            let croppedOffset = (CGFloat(self.height) - CGFloat(self.width) / screenAspectRatio) / 2.0
            pointsToPixels = CGFloat(self.width) / screenWidth
            
            cx = regionOfInterestCenterX * pointsToPixels
            cy = regionOfInterestCenterY * pointsToPixels + croppedOffset
        }
        
        let roiWidthInPixels = regionOfInterestLabelFrame.size.width * pointsToPixels
        let roiHeightInPixels = regionOfInterestLabelFrame.size.height * pointsToPixels
        return CGRect(x: cx - roiWidthInPixels * 0.5,
                      y: cy - roiHeightInPixels * 0.5,
                      width: roiWidthInPixels,
                      height: roiHeightInPixels)
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
