import UIKit

@available(iOS 11.2, *)
@objc public protocol SimpleScanDelegate {
    @objc func userDidCancelSimple(_ scanViewController: SimpleScanViewController)
    @objc func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard)
    @objc func userDidSkipSimple(_ scanViewController: SimpleScanViewController)
}

@available(iOS 11.2, *)
open class SimpleScanViewController: ScanBaseViewController {

    // used by ScanBase
    public var previewView: PreviewView = PreviewView()
    public var blurView: BlurView = BlurView()
    public var roiView: UIView = UIView()
    public var cornerView: CornerView?

    // our UI components
    public var descriptionText = UILabel()
    public var closeButton = UIButton()
    private var debugView: UIImageView?
    
    public weak var delegate: SimpleScanDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUiComponents()
        setupConstraints()
        
        setupOnViewDidLoad(regionOfInterestLabel: roiView, blurView: blurView, previewView: previewView, cornerView: cornerView, debugImageView: debugView, torchLevel: 1.0)
        startCameraPreview()
    }
    
    // MARK: -Visual and UI event setup for UI components
    open func setupUiComponents() {
        view.backgroundColor = .white
        regionOfInterestCornerRadius = 32.0

        let children: [UIView] = [previewView, blurView, roiView, descriptionText, closeButton]
        for child in children {
            self.view.addSubview(child)
        }
        
        setupPreviewViewUi()
        setupBlurViewUi()
        setupRoiViewUi()
        setupCloseButtonUi()
        setupDescriptionTextUi()
        
        if showDebugImageView {
            setupDebugViewUi()
        }
    }
    
    open func setupPreviewViewUi() {
        // no ui setup
    }
    
    open func setupBlurViewUi() {
        blurView.backgroundColor = #colorLiteral(red: 0.2411109507, green: 0.271378696, blue: 0.3280351758, alpha: 0.7020547945)
    }
    
    open func setupRoiViewUi() {
        roiView.layer.borderColor = UIColor.white.cgColor
    }
    
    open func setupCloseButtonUi() {
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.tintColor = .white
        closeButton.setTitle("Cancel", for: .normal)
        
        closeButton.addTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
    }
    
    open func setupDescriptionTextUi() {
        descriptionText.text = "Scan your card"
        descriptionText.textColor = .white
        descriptionText.font = descriptionText.font.withSize(30)
    }
    
    open func setupDebugViewUi() {
        debugView = UIImageView()
        guard let debugView = debugView else { return }
        self.view.addSubview(debugView)
    }
    
    // MARK: -Autolayout constraints
    open func setupConstraints() {
        let children: [UIView] = [previewView, blurView, roiView, descriptionText, closeButton]
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupPreviewViewConstraints()
        setupBlurViewConstraints()
        setupRoiViewConstraints()
        setupCloseButtonConstraints()
        setupDescriptionTextConstraints()
        
        if showDebugImageView {
            setupDebugViewConstraints()
        }
    }
    
    open func setupPreviewViewConstraints() {
        // make it full screen
        previewView.setAnchorsEqual(to: self.view)
    }
    
    open func setupBlurViewConstraints() {
        blurView.setAnchorsEqual(to: self.previewView)
    }
    
    open func setupRoiViewConstraints() {
        roiView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        roiView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
        roiView.heightAnchor.constraint(equalTo: roiView.widthAnchor, multiplier: 1.0 / 1.586).isActive = true
        roiView.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: 32).isActive = true
    }
    
    open func setupCloseButtonConstraints() {
        let margins = view.layoutMarginsGuide
        closeButton.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16.0).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
    }
    
    open func setupDescriptionTextConstraints() {
        descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        descriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
        descriptionText.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 32).isActive = true
        
    }
    
    open func setupDebugViewConstraints() {
        guard let debugView = debugView else { return }
        debugView.translatesAutoresizingMaskIntoConstraints = false
        
        debugView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        debugView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        debugView.widthAnchor.constraint(equalToConstant: 240).isActive = true
        debugView.heightAnchor.constraint(equalTo: debugView.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    // MARK: -Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        
        delegate?.userDidScanCardSimple(self, creditCard: card)
    }
    
    override open func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage) {
        super.prediction(prediction: prediction, squareCardImage: squareCardImage, fullCardImage: fullCardImage)
        //let centeredCard = prediction.centeredCardState ?? .noCard
        //let hasOcr = prediction.number != nil
        
        // XXX FIXME add UI stuff while we're scanning

    }
    
    // MARK: -UI event handlers
    @objc open func cancelButtonPress() {
        delegate?.userDidCancelSimple(self)
    }
}

public extension UIView {
    func setAnchorsEqual(to otherView: UIView) {
        self.topAnchor.constraint(equalTo: otherView.topAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: otherView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: otherView.trailingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = true
    }
}
