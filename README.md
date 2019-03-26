# CardScan

CardScan iOS installation guide

## Requirements

* Objective C or Swift 4.0 or higher
* iOS 11 or higher

## Installation

CardScan is available through [CocoaPods](https://cocoapods.org). To install
it, add the following line to your Podfile:

```ruby
pod 'CardScan', :git => 'git@github.com:getbouncer/cardscan-ios.git'
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

Alternatively, you can add this permission directly to your Info.plist
file:

```xml
<key>NSCameraUsageDescription</key>
<string>Scan credit cards</string>
```

## Configure CardScan (Optional)

To get faster performance on your first scan you can configure the library on app launch:

```swift
import UIKit
import CardScan

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    	Ocr.configure() 
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
        print(creditCard.number)
        self.dismiss(animated: true)
    }
}
```

## Authors

Sam King and Jaime Park

## License

CardScan is available under the BSD license. See the LICENSE file for more info.
