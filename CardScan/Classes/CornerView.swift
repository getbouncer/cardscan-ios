import UIKit

public class CornerView: UIView {
    
    func drawCorners(_ regionFrame: CGRect){
        let maskShapeLayer = CAShapeLayer()
        let maskPath = CGMutablePath()
        
        let boundX = self.bounds.origin.x
        let boundY = self.bounds.origin.y
        let boundWidth = self.bounds.width
        let boundHeight = self.bounds.height
        
        let cornerMultiplier = CGFloat(0.1)
        let cornerLength = regionFrame.width * cornerMultiplier
        
        //top left corner
        maskPath.move(to: self.bounds.origin)
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y:  boundY))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundY + cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX, y: boundY + cornerLength))
        maskPath.closeSubpath()
        
        //top right corner
        maskPath.move(to: CGPoint(x: boundWidth - cornerLength, y: boundY))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundY))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundY + cornerLength))
        maskPath.addLine(to: CGPoint(x:boundWidth - cornerLength, y: boundY + cornerLength))
        maskPath.closeSubpath()
        
        //bottom left corner
        maskPath.move(to: CGPoint(x: boundX, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundHeight))
        maskPath.addLine(to: CGPoint(x: boundX, y: boundHeight))
        maskPath.closeSubpath()
        
        //bottom right corner
        maskPath.move(to: CGPoint(x: boundWidth - cornerLength, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundHeight))
        maskPath.addLine(to: CGPoint(x: boundWidth - cornerLength, y: boundHeight))
        maskPath.closeSubpath()
        
        maskShapeLayer.path = maskPath
        self.layer.mask = maskShapeLayer
        
    }
    
    
}
