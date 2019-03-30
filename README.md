# CardScan

CardScan iOS installation guide

## Requirements

* Objective C or Swift 4.0 or higher
* iOS 11 or higher (supports development target of iOS 9.0 or higher)

## Installation

CardScan is available through [CocoaPods](https://cocoapods.org). To install
it, add the following line to your Podfile:

```ruby
pod 'CardScan', :git => 'git@github.com:getbouncer/cardscan-ios.git', :tag => '1.0.4034'
```

Or if you're using Stripe:

```ruby
pod 'CardScan', :git => 'git@github.com:getbouncer/cardscan-ios.git', :tag => '1.0.4034'
pod 'CardScan/Stripe', :git => 'git@github.com:getbouncer/cardscan-ios.git', :tag => '1.0.4034'
```

Make sure that you include the `use_frameworks!` line in your Podfile
since CardScan is a Framework written in Swift.

Next, install the new pod. From a terminal, run:

```
pod install
```

When using Cocoapods, you use the `.xcworkspace` instead of the
`.xcodeproj`. Again from the terminal, run:

```
open YourProject.xcworkspace
```

## Permissions

CardScan uses the camera, so you'll need to add an description of
camera usage to your Info.plist file:

![alt text](https://github.com/getbouncer/cardscan-ios/raw/master/Info.plist.camera.png "Info.plist")

The string you add here will be what CardScan displays to your users
when CardScan first prompts them for permission to use the camera.

![alt text](https://github.com/getbouncer/cardscan-ios/raw/master/camera_prompt.png "Camera prompt")

Alternatively, you can add this permission directly to your Info.plist
file:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan your card</string>
```

## Configure CardScan

Configure the library when your application launches:

```swift
import UIKit
import CardScan

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    	ScanViewController.configure() 
        // do any other necessary launch configuration
        return true
    }
}
```

## Using CardScan

To use CardScan, you create a `ScanViewController`, display it, and
implement the `ScanDelegate` protocol to get the results.

```swift
import UIKit
import CardScan

class ViewController: UIViewController, ScanDelegate {
    @IBAction func scanCardButtonPressed() {
        let vc = ScanViewController.createViewController(withDelegate: self)
        self.present(vc, animated: true)
    }

    func userDidSkip(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
    	let number = creditCard.number
	let expiryMonth = creditCard.expiryMonth
	let expiryYear = creditCard.expiryYear

	// If you're using Stripe and you include the CardScan/Stripe pod, you
  	// can get `STPCardParams` directly from CardScan `CreditCard` objects,
	// which you can use with Stripe's APIs
	let cardParams = creditCard.cardParams()

	// At this point you have the credit card number and optionally the expiry.
	// You can either tokenize the number or prompt the user for more
	// information (e.g., CVV) before tokenizing.

        self.dismiss(animated: true)
    }
}
```

## iOS 10 and older

CardScan makes heavy use of CoreML, which Apple introduced in iOS
11. You can include the CardScan library in any projects that support
a development target of iOS 9.0 or higher, but it will only run on
devices that are running iOS 11 or higher.

To check if a device supports CardScan at runtime using the
`ScanViewController.isCompatible` method:

```swift
if !ScanViewController.isCompatible() {
    self.scanCardButton.isHidden = true
}
```

## Authors

Sam King and Jaime Park

## License

CardScan is available under the BSD license. See the LICENSE file for more info.
