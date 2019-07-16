import UIKit

public class CornerView: UIView {
    var innerFrame: CGRect

    public required init?(coder aDecoder: NSCoder) {
        self.innerFrame = .zero
        super.init(coder: aDecoder)
        setUpView()
    }
    
    public override init(frame: CGRect) {
        self.innerFrame = frame
        super.init(frame: frame)
        setUpView()
    }
    
    public convenience init(frame: CGRect, borderWidth: CGFloat) {
        let cornerRectFrame =  CGRect(x: frame.origin.x - borderWidth,
                                      y: frame.origin.y - borderWidth,
                                      width: frame.width + (2.0 * borderWidth),
                                      height: frame.height + (2.0 * borderWidth))
        self.init(frame: cornerRectFrame)
        self.innerFrame = frame
        self.layer.borderWidth = borderWidth
        self.backgroundColor = UIColor.clear

    }
    
    private func setUpView(){
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func drawCorners(cornerColor: UIColor){
        self.layer.borderColor = cornerColor.cgColor
        
        let maskShapeLayer = CAShapeLayer()
        let maskPath = CGMutablePath()
        
        let boundX = self.bounds.origin.x
        let boundY = self.bounds.origin.y
        let boundWidth = self.bounds.width
        let boundHeight = self.bounds.height
        
        let cornerMultiplier = CGFloat(0.1)
        let cornerLength = self.innerFrame.width * cornerMultiplier
        
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
