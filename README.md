# CardScan

CardScan iOS installation guide

## Contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Permissions](#permissions)
* [Configure CardScan (Swift)](#configure-cardscan-swift)
* [Using CardScan (Swift)](#using-cardscan-swift)
* [iOS 10 and older (Swift)](#ios-10-and-older-swift)
* [Configure CardScan (Objective C)](#configure-cardscan-objective-c)
* [Using CardScan (Objective C)](#using-cardscan-objective-c)
* [iOS 10 and older (Objective C)](#ios-10-and-older-objective-c)
* [Authors](#authors)
* [License](#license)

## Requirements

* Objective C or Swift 4.0 or higher
* iOS 11 or higher (supports development target of iOS 10.0 or higher)
* iPhone 6s or newer (iPhone 6 and iPhone 6 plus are no longer supported)

## Installation

### CocoaPods

CardScan is available through [CocoaPods](https://cocoapods.org). To install
it, add the following line to your Podfile:

```ruby
pod 'CardScan'
```

Or if you're using Stripe:

```ruby
pod 'CardScan'
pod 'CardScan/Stripe'
```

Next, install the new pod. From a terminal, run:

```
pod install
```

When using Cocoapods, you use the `.xcworkspace` instead of the
`.xcodeproj`. Again from the terminal, run:

```
open YourProject.xcworkspace
```

### Carthage

CardScan is also available through [Carthage](https://github.com/Carthage/Carthage). To install it, add the following line to your Cartfile:

```ruby
github "getbouncer/cardscan-ios" "master"
```

Follow the [Carthage instructions for building for iOS](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos) 

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

## Configure CardScan (Swift)

Make sure that you get an [API
key](https://api.getbouncer.com/console) and configure the library
when your application launches.
If you are planning to use a navigation controller or support rotation, 
put in the following line.


```swift
import UIKit
import CardScan

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // if you need to get an API key you can get one from here:
	// https://api.getbouncer.com/console
    	ScanViewController.configure(apiKey: "YOUR_API_KEY_HERE") 
        // do any other necessary launch configuration
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // if you are planning to embed scanViewController into a navigation controller, 
        // put this line to handle rotations
        return ScanBaseViewController.supportedOrientationMaskOrDefault()
    }
}
```

By setting the API key the SDK will send anonymous stats to Bouncer's
servers. [This code
snippet](https://github.com/getbouncer/cardscan-ios/blob/da77e36c49f1de4b678e7ecaab56cc1466602716/CardScan/Classes/ScanStats.swift#L50)
shows what we send.

## Using CardScan (Swift)

To use CardScan, you create a `ScanViewController`, display it, and
implement the `ScanDelegate` protocol to get the results.

```swift
import UIKit
import CardScan

class ViewController: UIViewController, ScanDelegate {
    override func viewWillAppear() {
        super.viewWillAppear()
	
	// It's important that this goes in viewWillAppear because the user may deny permission
	// on the ScanViewController, in which case you'd want to hide the button to avoid
	// future presses
        if !ScanViewController.isCompatible() {
	    // Hide your "scan card" button because this device isn't compatible with CardScan
        }
    }
    
    @IBAction func scanCardButtonPressed() {
        guard let vc = ScanViewController.createViewController(withDelegate: self) else {
	    print("This device is incompatible with CardScan")
	    return
	}

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

## iOS 10 (Swift)

CardScan makes heavy use of CoreML, which Apple introduced in iOS
11. You can include the CardScan library in any projects that support
a development target of iOS 10.0 or higher, but it will only run on
devices that are running iOS 11 or higher.

To check if a device supports CardScan at runtime, use the
`ScanViewController.isCompatible` method:

```swift
if !ScanViewController.isCompatible() {
    self.scanCardButton.isHidden = true
}
```

## Configure CardScan (Objective C)

Make sure that you get an [API
key](https://api.getbouncer.com/console) and configure the library
when your application launches:

```objective-c
#import "AppDelegate.h"
@import CardScan;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // if you need to get an API key you can get one from here:
    // https://api.getbouncer.com/console
    [ScanViewController configureWithApiKey:@"YOUR_API_KEY_HERE"];
    return YES;
}

@end
```

By setting the API key the SDK will send anonymous stats to Bouncer's
servers. [This code
snippet](https://github.com/getbouncer/cardscan-ios/blob/da77e36c49f1de4b678e7ecaab56cc1466602716/CardScan/Classes/ScanStats.swift#L50)
shows what we send.

## Using CardScan (Objective C)

To use CardScan, you create a `ScanViewController`, display it, and
implement the `ScanDelegate` protocol to get the results.

```objective-c
#import "ViewController.h"
@import Stripe;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![ScanViewController isCompatible]) {
 	// Hide the "scan card" button because this device isn't compatible with CardScan       
    }
}

- (IBAction)scanCardPress:(id)sender {
    UIViewController *vc = [ScanViewController createViewControllerWithDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)userDidSkip:(ScanViewController * _Nonnull)scanViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidCancel:(ScanViewController * _Nonnull)scanViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidScanCard:(ScanViewController * _Nonnull)scanViewController creditCard:(CreditCard * _Nonnull)creditCard {
    NSString *number = creditCard.number;
    NSString *expiryMonth = creditCard.expiryMonth;
    NSString *expiryYear = creditCard.expiryYear;
    
    // If you're using Stripe and you include the CardScan/Stripe pod, you
    // can get `STPCardParams` directly from CardScan `CreditCard` objects,
    // which you can use with Stripe's APIs
    STPCardParams *cardParams = [creditCard cardParams];
    
    // At this point you have the credit card number and optionally the expiry.
    // You can either tokenize the number or prompt the user for more
    // information (e.g., CVV) before tokenizing.
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
```

## iOS 10 (Objective C)
CardScan makes heavy use of CoreML, which Apple introduced in iOS
11. You can include the CardScan library in any projects that support
a development target of iOS 10.0 or higher, but it will only run on
devices that are running iOS 11 or higher.

To check if a device supports CardScan at runtime, use the
`ScanViewController.isCompatible` method:

```objective-c
if (![ScanViewController isCompatible]) {
    self.scanCardButton.isHidden = true
}
```

## Adding to Your App

When added to your app successfully, you should see the card numbers
being passed into your payment form. This is what it looks like using a standard Stripe mobile payment form:

![alt text](https://raw.githubusercontent.com/getbouncer/cardscan-ios/master/card_scan.gif "Card Scan Gif")

## Authors

Sam King, Jaime Park, Zain ul Abi Din, and Andy Li

## License

CardScan is available under the BSD license. See the LICENSE file for more info.
